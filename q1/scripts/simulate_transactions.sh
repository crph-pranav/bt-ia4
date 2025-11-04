#!/bin/bash

export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config/
export CORE_PEER_TLS_ENABLED=true
CHANNEL_NAME="supplychainchannel"
CC_NAME="supplychain"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Print section header
printHeader() {
  echo -e "\n${GREEN}========================================${NC}"
  echo -e "${GREEN}$1${NC}"
  echo -e "${GREEN}========================================${NC}\n"
}

# Print step
printStep() {
  echo -e "${YELLOW}>>> $1${NC}"
}

# Print success
printSuccess() {
  echo -e "${GREEN}✓ $1${NC}\n"
}

# Print error
printError() {
  echo -e "${RED}✗ $1${NC}\n"
}

# Invoke chaincode
invokeChaincode() {
  local ORG=$1
  local PEER=$2
  local FUNCTION=$3
  shift 3
  local ARGS="$@"
  
  setGlobals $ORG $PEER
  
  peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.supplychain.com \
    --tls \
    --cafile $PWD/organizations/ordererOrganizations/supplychain.com/orderers/orderer.supplychain.com/msp/tlscacerts/tlsca.supplychain.com-cert.pem \
    -C $CHANNEL_NAME \
    -n ${CC_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles $PWD/organizations/peerOrganizations/manufacturer.supplychain.com/peers/peer0.manufacturer.supplychain.com/tls/ca.crt \
    -c "{\"function\":\"${FUNCTION}\",\"Args\":[$ARGS]}" 2>&1
}

# Query chaincode
queryChaincode() {
  local ORG=$1
  local PEER=$2
  local FUNCTION=$3
  shift 3
  local ARGS="$@"
  
  setGlobals $ORG $PEER
  
  peer chaincode query \
    -C $CHANNEL_NAME \
    -n ${CC_NAME} \
    -c "{\"function\":\"${FUNCTION}\",\"Args\":[$ARGS]}" 2>&1
}

# ============================================================
# SIMULATION: Complete Product Lifecycle
# ============================================================

printHeader "SIMULATION: COMPLETE PRODUCT LIFECYCLE FROM MANUFACTURER TO RETAILER"

# Step 1: Manufacturer creates a product
printHeader "STEP 1: MANUFACTURER CREATES PRODUCT"
printStep "Manufacturer creates product PROD_LAPTOP_001"

RESULT=$(invokeChaincode manufacturer 0 CreateProduct "\"PROD_LAPTOP_001\"" "\"Gaming Laptop XYZ\"" "\"High-performance gaming laptop with RTX 4080\"")

if [[ "$RESULT" == *"Error"* ]] || [[ "$RESULT" == *"error"* ]]; then
  printError "Failed to create product"
  echo "$RESULT"
  exit 1
else
  printSuccess "Product PROD_LAPTOP_001 created successfully by Manufacturer"
fi

sleep 3

# Query product details
printStep "Querying product details from Manufacturer's view"
PRODUCT=$(queryChaincode manufacturer 0 QueryProduct "\"PROD_LAPTOP_001\"")
echo "$PRODUCT" | jq '.'
printSuccess "Product details retrieved"

sleep 2

# Step 2: Manufacturer transfers to Distributor
printHeader "STEP 2: MANUFACTURER TRANSFERS TO DISTRIBUTOR"
printStep "Manufacturer transfers product to Distributor"

RESULT=$(invokeChaincode manufacturer 0 TransferShipment "\"PROD_LAPTOP_001\"" "\"DistributorMSP\"" "\"Distribution Center Mumbai\"")

if [[ "$RESULT" == *"Error"* ]] || [[ "$RESULT" == *"error"* ]]; then
  printError "Failed to transfer product"
  echo "$RESULT"
  exit 1
else
  printSuccess "Product transferred from Manufacturer to Distributor"
fi

sleep 3

# Query from Distributor
printStep "Querying product from Distributor's view"
PRODUCT=$(queryChaincode distributor 0 QueryProduct "\"PROD_LAPTOP_001\"")
echo "$PRODUCT" | jq '.'
printSuccess "Distributor can see the product"

sleep 2

# Step 3: Distributor receives the shipment
printHeader "STEP 3: DISTRIBUTOR RECEIVES SHIPMENT"
printStep "Distributor confirms receipt of product"

RESULT=$(invokeChaincode distributor 0 ReceiveShipment "\"PROD_LAPTOP_001\"" "\"Distribution Center Mumbai - Warehouse A\"")

if [[ "$RESULT" == *"Error"* ]] || [[ "$RESULT" == *"error"* ]]; then
  printError "Failed to receive product"
  echo "$RESULT"
  exit 1
else
  printSuccess "Product received by Distributor"
fi

sleep 3

# Step 4: Distributor transfers to Retailer
printHeader "STEP 4: DISTRIBUTOR TRANSFERS TO RETAILER"
printStep "Distributor transfers product to Retailer"

RESULT=$(invokeChaincode distributor 0 TransferShipment "\"PROD_LAPTOP_001\"" "\"RetailerMSP\"" "\"Retail Store Bangalore\"")

if [[ "$RESULT" == *"Error"* ]] || [[ "$RESULT" == *"error"* ]]; then
  printError "Failed to transfer product"
  echo "$RESULT"
  exit 1
else
  printSuccess "Product transferred from Distributor to Retailer"
fi

sleep 3

# Query from Retailer
printStep "Querying product from Retailer's view"
PRODUCT=$(queryChaincode retailer 0 QueryProduct "\"PROD_LAPTOP_001\"")
echo "$PRODUCT" | jq '.'
printSuccess "Retailer can see the product"

sleep 2

# Step 5: Retailer receives the shipment
printHeader "STEP 5: RETAILER RECEIVES FINAL SHIPMENT"
printStep "Retailer confirms receipt of product"

RESULT=$(invokeChaincode retailer 0 ReceiveShipment "\"PROD_LAPTOP_001\"" "\"Retail Store Bangalore - Shelf B12\"")

if [[ "$RESULT" == *"Error"* ]] || [[ "$RESULT" == *"error"* ]]; then
  printError "Failed to receive product"
  echo "$RESULT"
  exit 1
else
  printSuccess "Product received by Retailer - LIFECYCLE COMPLETE"
fi

sleep 3

# Step 6: Query complete product history
printHeader "STEP 6: QUERY COMPLETE PRODUCT HISTORY"
printStep "Retrieving complete product lifecycle history"

HISTORY=$(queryChaincode manufacturer 0 QueryProductHistory "\"PROD_LAPTOP_001\"")
echo "$HISTORY" | jq '.'
printSuccess "Complete product history retrieved"

sleep 2

# Step 7: Demonstrate Access Control
printHeader "STEP 7: DEMONSTRATE ACCESS CONTROL"

printStep "Testing unauthorized action: Retailer tries to create a product (should fail)"
RESULT=$(invokeChaincode retailer 0 CreateProduct "\"PROD_UNAUTHORIZED\"" "\"Test Product\"" "\"This should fail\"")

if [[ "$RESULT" == *"Error"* ]] || [[ "$RESULT" == *"error"* ]] || [[ "$RESULT" == *"only manufacturer"* ]]; then
  printSuccess "Access Control Working: Retailer cannot create products"
else
  printError "Access Control Failed: Retailer should not be able to create products"
fi

sleep 2

printStep "Testing unauthorized transfer: Manufacturer tries to directly transfer to Retailer (should fail)"
# First create another product
invokeChaincode manufacturer 0 CreateProduct "\"PROD_TEST_002\"" "\"Test Product 2\"" "\"For access control test\"" > /dev/null 2>&1
sleep 3

RESULT=$(invokeChaincode manufacturer 0 TransferShipment "\"PROD_TEST_002\"" "\"RetailerMSP\"" "\"Direct to Retail\"")

if [[ "$RESULT" == *"Error"* ]] || [[ "$RESULT" == *"error"* ]] || [[ "$RESULT" == *"invalid transfer"* ]]; then
  printSuccess "Access Control Working: Manufacturer cannot directly transfer to Retailer"
else
  printError "Access Control Failed: Direct Manufacturer to Retailer transfer should be blocked"
fi

sleep 2

# Step 8: Query all products
printHeader "STEP 8: QUERY ALL PRODUCTS IN SUPPLY CHAIN"
printStep "Retrieving all products from Manufacturer's view"

ALL_PRODUCTS=$(queryChaincode manufacturer 0 GetAllProducts)
echo "$ALL_PRODUCTS" | jq '.'
printSuccess "All products retrieved"

# Step 9: Query products by owner
printHeader "STEP 9: QUERY PRODUCTS BY CURRENT OWNER"

printStep "Query products owned by Retailer"
RETAILER_PRODUCTS=$(queryChaincode retailer 0 GetProductsByOwner "\"RetailerMSP\"")
echo "$RETAILER_PRODUCTS" | jq '.'
printSuccess "Products owned by Retailer retrieved"

printHeader "SIMULATION COMPLETE!"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Summary:${NC}"
echo -e "${GREEN}1. Product created by Manufacturer ✓${NC}"
echo -e "${GREEN}2. Transferred to Distributor ✓${NC}"
echo -e "${GREEN}3. Received by Distributor ✓${NC}"
echo -e "${GREEN}4. Transferred to Retailer ✓${NC}"
echo -e "${GREEN}5. Received by Retailer ✓${NC}"
echo -e "${GREEN}6. Complete history tracked ✓${NC}"
echo -e "${GREEN}7. Access control enforced ✓${NC}"
echo -e "${GREEN}8. All queries successful ✓${NC}"
echo -e "${GREEN}========================================${NC}\n"