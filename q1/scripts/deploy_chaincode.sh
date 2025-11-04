#!/bin/bash

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true

CHANNEL_NAME="supplychainchannel"
CC_NAME="supplychain"
CC_SRC_PATH="../chaincode/supply-chain"
CC_VERSION="1.0"
CC_SEQUENCE="1"
CC_INIT_FCN="InitLedger"
CC_END_POLICY="OR('ManufacturerMSP.peer','DistributorMSP.peer','RetailerMSP.peer')"
CC_COLL_CONFIG=""
DELAY="3"
MAX_RETRY="5"

# Set environment variables for peer
setGlobals() {
  local ORG=$1
  local PEER=$2
  
  if [ $ORG == "manufacturer" ]; then
    export CORE_PEER_LOCALMSPID="ManufacturerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/manufacturer.supplychain.com/peers/peer${PEER}.manufacturer.supplychain.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/manufacturer.supplychain.com/users/Admin@manufacturer.supplychain.com/msp
    export CORE_PEER_ADDRESS=localhost:$((7051 + PEER * 1000))
  elif [ $ORG == "distributor" ]; then
    export CORE_PEER_LOCALMSPID="DistributorMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/distributor.supplychain.com/peers/peer${PEER}.distributor.supplychain.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/distributor.supplychain.com/users/Admin@distributor.supplychain.com/msp
    export CORE_PEER_ADDRESS=localhost:$((9051 + PEER * 1000))
  elif [ $ORG == "retailer" ]; then
    export CORE_PEER_LOCALMSPID="RetailerMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/organizations/peerOrganizations/retailer.supplychain.com/peers/peer${PEER}.retailer.supplychain.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=$PWD/organizations/peerOrganizations/retailer.supplychain.com/users/Admin@retailer.supplychain.com/msp
    export CORE_PEER_ADDRESS=localhost:$((11051 + PEER * 1000))
  fi
}

# Package the chaincode
packageChaincode() {
  echo "========== Packaging chaincode =========="
  setGlobals manufacturer 0
  
  peer lifecycle chaincode package ${CC_NAME}.tar.gz \
    --path ${CC_SRC_PATH} \
    --lang golang \
    --label ${CC_NAME}_${CC_VERSION} >&log.txt
  
  res=$?
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "ERROR: Failed to package chaincode"
    exit 1
  fi
  echo "========== Chaincode packaged successfully =========="
}

# Install chaincode on peer
installChaincode() {
  ORG=$1
  PEER=$2
  
  setGlobals $ORG $PEER
  echo "========== Installing chaincode on peer${PEER}.${ORG} =========="
  
  peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
  res=$?
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "ERROR: Failed to install chaincode on peer${PEER}.${ORG}"
    exit 1
  fi
  echo "========== Chaincode installed on peer${PEER}.${ORG} =========="
}

# Query installed chaincode
queryInstalled() {
  ORG=$1
  PEER=$2
  
  setGlobals $ORG $PEER
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  cat log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  echo "========== Package ID: ${PACKAGE_ID} =========="
}

# Approve chaincode for org
approveForMyOrg() {
  ORG=$1
  PEER=$2
  
  setGlobals $ORG $PEER
  
  # Get Package ID
  peer lifecycle chaincode queryinstalled >&log.txt
  PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  
  echo "========== Approving chaincode for ${ORG} =========="
  
  peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.supplychain.com \
    --tls \
    --cafile $PWD/organizations/ordererOrganizations/supplychain.com/orderers/orderer.supplychain.com/msp/tlscacerts/tlsca.supplychain.com-cert.pem \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence ${CC_SEQUENCE} \
    --init-required \
    --signature-policy "${CC_END_POLICY}" >&log.txt
  
  res=$?
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "ERROR: Failed to approve chaincode for ${ORG}"
    exit 1
  fi
  echo "========== Chaincode approved for ${ORG} =========="
}

# Check commit readiness
checkCommitReadiness() {
  echo "========== Checking commit readiness =========="
  setGlobals manufacturer 0
  
  peer lifecycle chaincode checkcommitreadiness \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    --init-required \
    --signature-policy "${CC_END_POLICY}" \
    --output json
}

# Commit chaincode definition
commitChaincodeDefinition() {
  echo "========== Committing chaincode definition =========="
  
  peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.supplychain.com \
    --tls \
    --cafile $PWD/organizations/ordererOrganizations/supplychain.com/orderers/orderer.supplychain.com/msp/tlscacerts/tlsca.supplychain.com-cert.pem \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    --init-required \
    --signature-policy "${CC_END_POLICY}" \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles $PWD/organizations/peerOrganizations/manufacturer.supplychain.com/peers/peer0.manufacturer.supplychain.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles $PWD/organizations/peerOrganizations/distributor.supplychain.com/peers/peer0.distributor.supplychain.com/tls/ca.crt \
    --peerAddresses localhost:11051 \
    --tlsRootCertFiles $PWD/organizations/peerOrganizations/retailer.supplychain.com/peers/peer0.retailer.supplychain.com/tls/ca.crt >&log.txt
  
  res=$?
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "ERROR: Failed to commit chaincode definition"
    exit 1
  fi
  echo "========== Chaincode definition committed =========="
}

# Query committed chaincode
queryCommitted() {
  echo "========== Querying committed chaincode =========="
  setGlobals manufacturer 0
  
  peer lifecycle chaincode querycommitted \
    --channelID $CHANNEL_NAME \
    --name ${CC_NAME}
}

# Initialize chaincode
chaincodeInvoke() {
  echo "========== Initializing chaincode =========="
  setGlobals manufacturer 0
  
  peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.supplychain.com \
    --tls \
    --cafile $PWD/organizations/ordererOrganizations/supplychain.com/orderers/orderer.supplychain.com/msp/tlscacerts/tlsca.supplychain.com-cert.pem \
    -C $CHANNEL_NAME \
    -n ${CC_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles $PWD/organizations/peerOrganizations/manufacturer.supplychain.com/peers/peer0.manufacturer.supplychain.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles $PWD/organizations/peerOrganizations/distributor.supplychain.com/peers/peer0.distributor.supplychain.com/tls/ca.crt \
    --isInit \
    -c '{"function":"InitLedger","Args":[]}' >&log.txt
  
  res=$?
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "ERROR: Failed to initialize chaincode"
    exit 1
  fi
  echo "========== Chaincode initialized =========="
}

# Main deployment flow
echo "========== Starting Chaincode Deployment =========="

packageChaincode

installChaincode manufacturer 0
installChaincode manufacturer 1
installChaincode distributor 0
installChaincode distributor 1
installChaincode retailer 0
installChaincode retailer 1

queryInstalled manufacturer 0

approveForMyOrg manufacturer 0
approveForMyOrg distributor 0
approveForMyOrg retailer 0

checkCommitReadiness

commitChaincodeDefinition

queryCommitted

sleep 3

chaincodeInvoke

echo "========== Chaincode Deployment Complete =========="