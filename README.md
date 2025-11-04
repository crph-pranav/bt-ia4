# Blockchain Technology (ICT4415) - Internal Assessment 4
## Supply Chain Management & Security Analysis

---

## 🎯 Overview

This repository contains complete solutions for Internal Assessment 4, implementing:

### Question 1: Hyperledger Fabric Supply Chain Network
- **3 Organizations**: Manufacturer, Distributor, Retailer
- **Private Channels**: Role-based access control
- **Smart Chaincode**: Product lifecycle tracking
- **Complete Simulation**: End-to-end product journey

### Question 2: Blockchain Security Analysis
- **Threat Identification**: Double-spending, Sybil attacks, Smart contract exploits
- **Threat Modeling**: STRIDE framework, Attack trees
- **Mitigation Strategies**: Comprehensive solutions with code examples
- **Practical Demonstrations**: Attack scenarios and defenses

---

## 📦 Question 1: Supply Chain Network

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Supply Chain Network                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  │ Manufacturer │─────>│ Distributor  │─────>│   Retailer   │
│  │              │      │              │      │              │
│  │ - Create     │      │ - Receive    │      │ - Receive    │
│  │ - Transfer   │      │ - Transfer   │      │ - Final Sale │
│  └──────────────┘      └──────────────┘      └──────────────┘
│         │                      │                      │
│         │                      │                      │
│         └──────────────────────┴──────────────────────┘
│                            │
│                            │
│                    ┌───────▼────────┐
│                    │   Orderer      │
│                    │   (Consensus)  │
│                    └────────────────┘
│                            │
│                    ┌───────▼────────┐
│                    │  Shared Ledger │
│                    │  (Blockchain)  │
│                    └────────────────┘
└─────────────────────────────────────────────────────────────┘
```

### Key Features

#### 1. Network Components
- **3 Organizations**: Each with 2 peers
- **1 Orderer**: Solo consensus (can be upgraded to Raft)
- **Multiple Channels**: For private communication
- **TLS Enabled**: Secure communication

#### 2. Chaincode Functions
```go
// Product Creation
CreateProduct(productID, name, description) -> Product

// Shipment Transfer
TransferShipment(productID, toOrg, location) -> Product

// Shipment Receipt
ReceiveShipment(productID, location) -> Product

// Query Functions
QueryProduct(productID) -> Product
QueryProductHistory(productID) -> []ShipmentEvent
GetAllProducts() -> []Product
GetProductsByOwner(owner) -> []Product
GetProductHistory(productID) -> []QueryResult
```

#### 3. Access Control Rules
- **Manufacturer**: Can create products, transfer to Distributor only
- **Distributor**: Can receive from Manufacturer, transfer to Retailer
- **Retailer**: Can receive from Distributor, mark as final delivery
- **All**: Can query products they own or have owned

#### 4. Product Lifecycle States
```
CREATED → IN_TRANSIT → DELIVERED
```

---

## 🔐 Question 2: Security Analysis

### Threats Analyzed

#### 1. Double-Spending Attack
**Risk Level**: Critical (CVSS 9.1)
- **Attack Vectors**: Race attacks, 51% attacks, finality exploitation
- **Mitigations**: BFT consensus, multi-sig validation, finality monitoring
- **Example**: Vulnerable vs. secure transaction validation

#### 2. Sybil Attack
**Risk Level**: High (CVSS 8.6)
- **Attack Vectors**: Identity forgery, network flooding, eclipse attacks
- **Mitigations**: Proof-of-Stake, reputation systems, rate limiting
- **Example**: Staking contracts and reputation scoring

#### 3. Smart Contract Exploits
**Risk Level**: Critical (CVSS 9.8)
- **Attack Vectors**: Reentrancy, overflow, access control bypass
- **Mitigations**: Code audits, formal verification, circuit breakers
- **Example**: Reentrancy attack demonstration and prevention

---

## 🚀 Setup Instructions

### Step 1: Install Prerequisites

#### Ubuntu/Debian
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Go
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install jq
sudo apt install jq -y

# Log out and log back in for Docker group changes
```

#### macOS
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# Install Go
brew install go

# Install jq
brew install jq
```

### Step 2: Install Hyperledger Fabric

```bash
# Create working directory
mkdir -p ~/fabric
cd ~/fabric

# Download Fabric binaries and Docker images
curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.5.0 1.5.5

# Add binaries to PATH
echo 'export PATH=$PATH:~/fabric/fabric-samples/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
peer version
orderer version
```

### Step 3: Clone Repository

```bash
# Clone the repository
git clone https://github.com/yourusername/blockchain-assessment-4.git
cd blockchain-assessment-4
```

---

## ▶️ Running the Project

### Question 1: Supply Chain Network

#### Step 1: Generate Crypto Material
```bash
cd q1-supply-chain

# Generate certificates and genesis block
./scripts/network.sh generate
```

Expected output:
```
##########################################################
##### Generate certificates using cryptogen tool #########
##########################################################
manufacturer.supplychain.com
distributor.supplychain.com
retailer.supplychain.com

#########  Generating Orderer Genesis block ##############
Genesis block generated successfully
```

#### Step 2: Start the Network
```bash
# Bring up the network
./scripts/network.sh up

# Verify all containers are running
docker ps
```

Expected containers:
- orderer.supplychain.com
- peer0.manufacturer.supplychain.com
- peer1.manufacturer.supplychain.com
- peer0.distributor.supplychain.com
- peer1.distributor.supplychain.com
- peer0.retailer.supplychain.com
- peer1.retailer.supplychain.com
- cli

#### Step 3: Create Channels
```bash
# Create main supply chain channel
./scripts/createChannel.sh supplychainchannel

# Create private channels (optional)
./scripts/createChannel.sh manudistchannel
./scripts/createChannel.sh distretailchannel
```

#### Step 4: Deploy Chaincode
```bash
# Deploy and initialize chaincode
./scripts/deployChaincode.sh

# This script will:
# 1. Package the chaincode
# 2. Install on all peers
# 3. Approve for all organizations
# 4. Commit chaincode definition
# 5. Initialize the ledger
```

#### Step 5: Simulate Transactions
```bash
# Run the complete product lifecycle simulation
./scripts/simulateTransactions.sh
```

This will demonstrate:
1. ✅ Product creation by Manufacturer
2. ✅ Transfer to Distributor
3. ✅ Receipt by Distributor
4. ✅ Transfer to Retailer
5. ✅ Receipt by Retailer
6. ✅ Complete history query
7. ✅ Access control verification
8. ✅ Query operations

#### Expected Output:
```
========================================
STEP 1: MANUFACTURER CREATES PRODUCT
========================================

>>> Manufacturer creates product PROD_LAPTOP_001
✓ Product PROD_LAPTOP_001 created successfully by Manufacturer

>>> Querying product details from Manufacturer's view
{
  "productID": "PROD_LAPTOP_001",
  "name": "Gaming Laptop XYZ",
  "description": "High-performance gaming laptop with RTX 4080",
  "manufacturer": "ManufacturerMSP",
  "currentOwner": "ManufacturerMSP",
  "status": "CREATED",
  ...
}

[Similar detailed output for each step]

========================================
SIMULATION COMPLETE!
========================================
Summary:
1. Product created by Manufacturer ✓
2. Transferred to Distributor ✓
3. Received by Distributor ✓
4. Transferred to Retailer ✓
5. Received by Retailer ✓
6. Complete history tracked ✓
7. Access control enforced ✓
8. All queries successful ✓
========================================
```

#### Step 6: Manual Testing (Optional)
```bash
# Enter CLI container
docker exec -it cli bash

# Set environment for Manufacturer
export CORE_PEER_LOCALMSPID="ManufacturerMSP"
export CORE_PEER_ADDRESS=peer0.manufacturer.supplychain.com:7051
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/manufacturer.supplychain.com/users/Admin@manufacturer.supplychain.com/msp

# Create a product
peer chaincode invoke \
  -o orderer.supplychain.com:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/supplychain.com/orderers/orderer.supplychain.com/msp/tlscacerts/tlsca.supplychain.com-cert.pem \
  -C supplychainchannel \
  -n supplychain \
  -c '{"function":"CreateProduct","Args":["PROD002","Smartphone XYZ","5G Smartphone"]}'

# Query the product
peer chaincode query \
  -C supplychainchannel \
  -n supplychain \
  -c '{"function":"QueryProduct","Args":["PROD002"]}'
```

#### Step 7: Stop the Network
```bash
# Stop and clean up
./scripts/network.sh down
```
