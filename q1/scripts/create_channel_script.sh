#!/bin/bash

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true

CHANNEL_NAME=${1:-"supplychainchannel"}
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"

# Set environment for organization
setGlobals() {
  local ORG=$1
  local PEER=${2:-0}
  
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

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Create channel transaction
createChannelTx() {
  echo "========== Generating channel create transaction: ${CHANNEL_NAME}.tx =========="
  
  set -x
  configtxgen -profile SupplyChainChannel \
    -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx \
    -channelID $CHANNEL_NAME
  res=$?
  { set +x; } 2>/dev/null
  
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi
  echo "========== Channel transaction generated =========="
}

# Create the channel
createChannel() {
  setGlobals manufacturer 0
  
  echo "========== Creating channel ${CHANNEL_NAME} =========="
  
  local rc=1
  local COUNTER=1
  
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel create \
      -o localhost:7050 \
      -c $CHANNEL_NAME \
      --ordererTLSHostnameOverride orderer.supplychain.com \
      -f ./channel-artifacts/${CHANNEL_NAME}.tx \
      --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block \
      --tls \
      --cafile $PWD/organizations/ordererOrganizations/supplychain.com/orderers/orderer.supplychain.com/msp/tlscacerts/tlsca.supplychain.com-cert.pem >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  
  cat log.txt
  
  if [ $rc -ne 0 ]; then
    echo "Failed to create channel $CHANNEL_NAME"
    exit 1
  fi
  
  echo "========== Channel $CHANNEL_NAME created =========="
}

# Join peer to channel
joinChannel() {
  local ORG=$1
  local PEER=$2
  
  setGlobals $ORG $PEER
  
  echo "========== Joining peer${PEER}.${ORG} to channel ${CHANNEL_NAME} =========="
  
  local rc=1
  local COUNTER=1
  
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b ./channel-artifacts/${CHANNEL_NAME}.block >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    
    let rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done
  
  cat log.txt
  
  if [ $rc -ne 0 ]; then
    echo "Failed to join peer${PEER}.${ORG} to channel $CHANNEL_NAME"
    exit 1
  fi
  
  echo "========== peer${PEER}.${ORG} joined channel ${CHANNEL_NAME} =========="
}

# Update anchor peer
updateAnchorPeers() {
  local ORG=$1
  
  setGlobals $ORG 0
  
  echo "========== Updating anchor peers for ${ORG} =========="
  
  local OUTPUT_ANCHOR="./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx"
  
  set -x
  configtxgen -profile SupplyChainChannel \
    -outputAnchorPeersUpdate ${OUTPUT_ANCHOR} \
    -channelID $CHANNEL_NAME \
    -asOrg ${CORE_PEER_LOCALMSPID}
  res=$?
  { set +x; } 2>/dev/null
  
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for ${ORG}"
    exit 1
  fi
  
  set -x
  peer channel update \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.supplychain.com \
    -c $CHANNEL_NAME \
    -f ${OUTPUT_ANCHOR} \
    --tls \
    --cafile $PWD/organizations/ordererOrganizations/supplychain.com/orderers/orderer.supplychain.com/msp/tlscacerts/tlsca.supplychain.com-cert.pem >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  
  cat log.txt
  
  if [ $res -ne 0 ]; then
    echo "Failed to update anchor peer for ${ORG}"
    exit 1
  fi
  
  echo "========== Anchor peer updated for ${ORG} =========="
}

# List channels
listChannels() {
  local ORG=$1
  local PEER=${2:-0}
  
  setGlobals $ORG $PEER
  
  echo "========== Listing channels for peer${PEER}.${ORG} =========="
  
  set -x
  peer channel list
  res=$?
  { set +x; } 2>/dev/null
  
  if [ $res -ne 0 ]; then
    echo "Failed to list channels"
    exit 1
  fi
}

# Get channel info
getChannelInfo() {
  local ORG=$1
  local PEER=${2:-0}
  
  setGlobals $ORG $PEER
  
  echo "========== Getting channel info from peer${PEER}.${ORG} =========="
  
  set -x
  peer channel getinfo -c $CHANNEL_NAME
  res=$?
  { set +x; } 2>/dev/null
  
  if [ $res -ne 0 ]; then
    echo "Failed to get channel info"
    exit 1
  fi
}

# Main execution
echo "========== Channel Creation Script =========="
echo "Channel Name: $CHANNEL_NAME"
echo

# Generate channel configuration
if [ ! -f "./channel-artifacts/${CHANNEL_NAME}.tx" ]; then
  createChannelTx
fi

# Create the channel
if [ ! -f "./channel-artifacts/${CHANNEL_NAME}.block" ]; then
  createChannel
else
  echo "Channel block already exists, skipping creation"
fi

# Join all peers to channel
echo
echo "========== Joining Peers to Channel =========="

joinChannel manufacturer 0
joinChannel manufacturer 1
joinChannel distributor 0
joinChannel distributor 1
joinChannel retailer 0
joinChannel retailer 1

# Update anchor peers for each organization
echo
echo "========== Updating Anchor Peers =========="

updateAnchorPeers manufacturer
updateAnchorPeers distributor
updateAnchorPeers retailer

# Verify channel creation
echo
echo "========== Verifying Channel Setup =========="

listChannels manufacturer 0
getChannelInfo manufacturer 0

echo
echo "========== Channel Setup Complete =========="
echo "Channel Name: $CHANNEL_NAME"
echo "All peers have joined the channel"
echo "Anchor peers updated for all organizations"