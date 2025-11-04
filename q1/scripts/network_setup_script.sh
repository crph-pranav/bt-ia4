#!/bin/bash

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  network.sh <Mode> [Flags]"
  echo "    <Mode>"
  echo "      - 'up' - bring up fabric network with docker-compose"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "      - 'deployCC' - deploy the chaincode"
  echo
  echo "    Flags:"
  echo "    -ca <use CAs> -  create Certificate Authorities"
  echo "    -c <channel name> - channel name to use (defaults to \"supplychainchannel\")"
  echo "    -s <dbtype> - the database backend to use: goleveldb (default) or couchdb"
  echo "    -verbose - verbose mode"
  echo
  echo " Examples:"
  echo "   network.sh up"
  echo "   network.sh up -ca"
  echo "   network.sh deployCC"
}

# Obtain CONTAINER_IDS and remove them
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Generate the needed certificates, genesis block and channel configuration
function generateCerts() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  # Generate crypto material for manufacturers
  cryptogen generate --config=./organizations/cryptogen/crypto-config-manufacturer.yaml --output="organizations"
  
  # Generate crypto material for distributors
  cryptogen generate --config=./organizations/cryptogen/crypto-config-distributor.yaml --output="organizations"
  
  # Generate crypto material for retailers
  cryptogen generate --config=./organizations/cryptogen/crypto-config-retailer.yaml --output="organizations"
  
  # Generate crypto material for orderer
  cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"

  echo
  echo "Generate CCP files for organizations"
  ./organizations/ccp-generate.sh
}

# Generate orderer system channel genesis block.
function generateGenesisBlock() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo "#########  Generating Orderer Genesis block ##############"
  
  set -x
  configtxgen -profile ThreeOrgsApplicationGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
}

# Generate channel configuration transaction
function generateChannelTx() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi
  
  CHANNEL_NAME=$1
  PROFILE=$2
  
  echo "#########  Generating channel transaction '$CHANNEL_NAME.tx' ##############"
  set -x
  configtxgen -profile $PROFILE -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi
}

# Generate anchor peer update for org
function generateAnchorPeerUpdate() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  CHANNEL_NAME=$1
  ORG=$2
  
  echo "#########  Generating anchor peer update for $ORG ##############"
  set -x
  configtxgen -profile SupplyChainChannel -outputAnchorPeersUpdate ./channel-artifacts/${ORG}anchors.tx -channelID $CHANNEL_NAME -asOrg ${ORG}MSP
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for $ORG..."
    exit 1
  fi
}

# Bring up network
function networkUp() {
  if [ ! -d "organizations/peerOrganizations" ]; then
    echo "Generating certificates and genesis block..."
    generateCerts
    generateGenesisBlock
  fi

  COMPOSE_FILES="-f docker/docker-compose-network.yaml"
  
  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi
}

# Tear down running network
function networkDown() {
  docker-compose -f docker/docker-compose-network.yaml down --volumes --remove-orphans
  
  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes
    docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf channel-artifacts/*.block channel-artifacts/*.tx'
    # remove orderer block and other channel configuration transactions and certs
    rm -rf organizations/peerOrganizations organizations/ordererOrganizations
    ## remove fabric ca artifacts
    rm -rf organizations/fabric-ca/manufacturer/msp organizations/fabric-ca/manufacturer/tls-cert.pem organizations/fabric-ca/manufacturer/ca-cert.pem organizations/fabric-ca/manufacturer/IssuerPublicKey organizations/fabric-ca/manufacturer/IssuerRevocationPublicKey organizations/fabric-ca/manufacturer/fabric-ca-server.db
    rm -rf organizations/fabric-ca/distributor/msp organizations/fabric-ca/distributor/tls-cert.pem organizations/fabric-ca/distributor/ca-cert.pem organizations/fabric-ca/distributor/IssuerPublicKey organizations/fabric-ca/distributor/IssuerRevocationPublicKey organizations/fabric-ca/distributor/fabric-ca-server.db
    rm -rf organizations/fabric-ca/retailer/msp organizations/fabric-ca/retailer/tls-cert.pem organizations/fabric-ca/retailer/ca-cert.pem organizations/fabric-ca/retailer/IssuerPublicKey organizations/fabric-ca/retailer/IssuerRevocationPublicKey organizations/fabric-ca/retailer/fabric-ca-server.db
    rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db
  fi

  clearContainers
  removeUnwantedImages
}

# Parse commandline args
MODE=$1
shift

# parse flags
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    printHelp
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -verbose )
    VERBOSE=true
    shift
    ;;
  * )
    echo "Unknown flag: $key"
    printHelp
    exit 1
    ;;
  esac
  shift
done

# Determine mode of operation and printing out what we asked for
if [ "$MODE" == "up" ]; then
  echo "Starting network"
  networkUp
elif [ "$MODE" == "down" ]; then
  echo "Stopping network"
  networkDown
elif [ "$MODE" == "generate" ]; then
  echo "Generating network artifacts"
  generateCerts
  generateGenesisBlock
elif [ "$MODE" == "restart" ]; then
  echo "Restarting network"
  networkDown
  networkUp
else
  printHelp
  exit 1
fi