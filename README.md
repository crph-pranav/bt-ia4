# Blockchain Technology (ICT4415) - Internal Assessment 4
## Supply Chain Management & Security Analysis

---

## 📋 Table of Contents
1. [Overview](#overview)
2. [Repository Structure](#repository-structure)
3. [Prerequisites](#prerequisites)
4. [Question 1: Supply Chain Network](#question-1-supply-chain-network)
5. [Question 2: Security Analysis](#question-2-security-analysis)
6. [Setup Instructions](#setup-instructions)
7. [Running the Project](#running-the-project)
8. [Testing & Verification](#testing--verification)
9. [Troubleshooting](#troubleshooting)
10. [Additional Resources](#additional-resources)

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

## 📁 Repository Structure

```
blockchain-assessment-4/
├── README.md                          # This file
│
├── question1-supply-chain/
│   ├── README.md                      # Q1 specific documentation
│   │
│   ├── docker/
│   │   └── docker-compose-network.yaml  # Network configuration
│   │
│   ├── configtx/
│   │   └── configtx.yaml              # Channel configuration
│   │
│   ├── organizations/
│   │   └── cryptogen/
│   │       ├── crypto-config-manufacturer.yaml
│   │       ├── crypto-config-distributor.yaml
│   │       ├── crypto-config-retailer.yaml
│   │       └── crypto-config-orderer.yaml
│   │
│   ├── chaincode/
│   │   └── supply-chain/
│   │       ├── supplychain.go         # Main chaincode
│   │       ├── go.mod
│   │       └── go.sum
│   │
│   ├── scripts/
│   │   ├── network.sh                 # Network management script
│   │   ├── deployChaincode.sh         # Chaincode deployment
│   │   ├── createChannel.sh           # Channel creation
│   │   └── simulateTransactions.sh    # Transaction simulation
│   │
│   ├── channel-artifacts/             # Generated channel artifacts
│   │
│   └── screenshots/                   # Execution screenshots
│       ├── network-up.png
│       ├── chaincode-deployment.png
│       ├── transaction-flow.png
│       └── access-control-demo.png
│
├── question2-security/
│   ├── README.md                      # Q2 specific documentation
│   │
│   ├── reports/
│   │   ├── Security-Analysis-Report.pdf
│   │   ├── Security-Analysis-Report.md
│   │   └── Threat-Modeling-Diagrams.pdf
│   │
│   ├── code-examples/
│   │   ├── double-spending/
│   │   │   ├── vulnerable-contract.sol
│   │   │   ├── attacker-contract.sol
│   │   │   └── secure-contract.sol
│   │   │
│   │   ├── sybil-protection/
│   │   │   ├── validator-staking.sol
│   │   │   ├── reputation-system.py
│   │   │   └── network-config.yaml
│   │   │
│   │   └── contract-security/
│   │       ├── circuit-breaker.sol
│   │       ├── secure-vault.sol
│   │       ├── monitoring.py
│   │       └── audit-checklist.md
│   │
│   ├── threat-modeling/
│   │   ├── attack-trees/
│   │   ├── stride-analysis.xlsx
│   │   └── risk-matrix.pdf
│   │
│   └── mitigation-demos/
│       ├── demo1-double-spending-prevention.md
│       ├── demo2-sybil-resistance.md
│       └── demo3-contract-security.md
│
└── docs/
    ├── installation-guide.md
    ├── architecture-diagram.pdf
    ├── api-documentation.md
    └── presentation.pptx
```

---

## 🔧 Prerequisites

### Required Software
- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 1.29 or higher
- **Go**: Version 1.19 or higher
- **Node.js**: Version 16.x or higher (optional, for testing)
- **jq**: For JSON parsing in scripts

### Hyperledger Fabric Components
- **Fabric Binaries**: Version 2.5
- **Fabric Docker Images**: Version 2.5

### System Requirements
- **OS**: Ubuntu 20.04/22.04, macOS 11+, or Windows 10/11 with WSL2
- **RAM**: Minimum 8GB (16GB recommended)
- **Disk Space**: 20GB free space
- **CPU**: 4 cores recommended

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

### Deliverables
1. **Comprehensive Report**: 30+ pages with detailed analysis
2. **Code Examples**: Vulnerable and secure implementations
3. **Threat Models**: STRIDE analysis and attack trees
4. **Mitigation Strategies**: Practical, implementable solutions
5. **Monitoring Tools**: Security monitoring dashboard code

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
cd question1-supply-chain

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

---

### Question 2: Security Analysis

The security analysis is provided in document format. To view:

```bash
cd question2-security/reports

# View the main report
cat Security-Analysis-Report.md

# Or open PDF
xdg-open Security-Analysis-Report.pdf  # Linux
open Security-Analysis-Report.pdf      # macOS
```

#### Testing Security Examples

##### 1. Double-Spending Prevention Test
```bash
cd question2-security/code-examples/double-spending

# Deploy vulnerable contract
truffle migrate --network development --f 1 --to 1

# Run attack simulation
truffle test test/double-spending-attack.js

# Deploy secure contract
truffle migrate --network development --f 2 --to 2

# Verify protection
truffle test test/double-spending-protected.js
```

##### 2. Sybil Attack Resistance Test
```bash
cd question2-security/code-examples/sybil-protection

# Deploy staking contract
truffle migrate --network development

# Run reputation system simulation
python3 reputation-system.py

# Test network rate limiting
python3 test-rate-limiting.py
```

##### 3. Smart Contract Security Test
```bash
cd question2-security/code-examples/contract-security

# Run security analysis tools
slither secure-vault.sol
mythril analyze secure-vault.sol

# Test circuit breaker
truffle test test/circuit-breaker-test.js

# Run monitoring simulation
python3 monitoring.py
```

---

## ✅ Testing & Verification

### Automated Tests

#### Network Health Check
```bash
cd question1-supply-chain

# Check all containers are running
docker ps --format "table {{.Names}}\t{{.Status}}" | grep supplychain

# Check peer connectivity
docker exec peer0.manufacturer.supplychain.com peer channel list

# Check chaincode installation
docker exec peer0.manufacturer.supplychain.com peer lifecycle chaincode queryinstalled
```

#### Chaincode Tests
```bash
# Run Go tests for chaincode
cd chaincode/supply-chain
go test -v ./...

# Test coverage
go test -cover ./...
```

### Manual Verification Checklist

#### Network Setup ✓
- [ ] All Docker containers running
- [ ] All peers connected to orderer
- [ ] Channels created successfully
- [ ] Chaincode deployed on all peers

#### Chaincode Functionality ✓
- [ ] Product creation works
- [ ] Transfer from Manufacturer to Distributor works
- [ ] Transfer from Distributor to Retailer works
- [ ] Receipt confirmation works
- [ ] Query functions return correct data
- [ ] History tracking is accurate

#### Access Control ✓
- [ ] Manufacturer can create products
- [ ] Retailer cannot create products
- [ ] Manufacturer cannot directly transfer to Retailer
- [ ] Only current owner can transfer product
- [ ] All organizations can query their products

#### Security Features ✓
- [ ] TLS enabled on all connections
- [ ] Certificate authentication working
- [ ] Transaction endorsement required
- [ ] Consensus mechanism functioning
- [ ] Audit trail maintained

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: Docker Permission Denied
```bash
# Error: permission denied while connecting to Docker daemon
# Solution:
sudo usermod -aG docker $USER
newgrp docker
# Or log out and log back in
```

#### Issue 2: Port Already in Use
```bash
# Error: port is already allocated
# Solution: Check and kill processes using ports
sudo lsof -i :7050  # Check orderer port
sudo lsof -i :7051  # Check peer port

# Kill the process
sudo kill -9 <PID>

# Or stop all Docker containers
docker stop $(docker ps -aq)
```

#### Issue 3: Chaincode Installation Failed
```bash
# Error: chaincode install failed
# Solution: Check Go dependencies
cd chaincode/supply-chain
go mod tidy
go mod vendor

# Rebuild and redeploy
cd ../../
./scripts/deployChaincode.sh
```

#### Issue 4: Peer Cannot Connect to Orderer
```bash
# Check orderer logs
docker logs orderer.supplychain.com

# Check peer logs
docker logs peer0.manufacturer.supplychain.com

# Verify network connectivity
docker exec peer0.manufacturer.supplychain.com ping orderer.supplychain.com

# Restart network if needed
./scripts/network.sh restart
```

#### Issue 5: Transaction Endorsement Failed
```bash
# Error: endorsement policy not satisfied
# Solution: Check endorsement policy
peer lifecycle chaincode querycommitted -C supplychainchannel -n supplychain

# Verify all required peers are endorsing
# Modify endorsement policy if needed in deployChaincode.sh
```

### Debug Mode

Enable verbose logging:
```bash
# Set environment variables
export FABRIC_LOGGING_SPEC=DEBUG
export CORE_CHAINCODE_LOGGING_LEVEL=DEBUG

# Run commands with verbose output
./scripts/network.sh up -verbose
```

### Clean Reset

Complete cleanup and fresh start:
```bash
# Stop everything
./scripts/network.sh down

# Remove all Docker volumes
docker volume prune -f

# Remove generated artifacts
rm -rf organizations/peerOrganizations organizations/ordererOrganizations
rm -rf channel-artifacts/*.block channel-artifacts/*.tx

# Regenerate and restart
./scripts/network.sh generate
./scripts/network.sh up
```

---

## 📚 Additional Resources

### Documentation
- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Fabric Samples](https://github.com/hyperledger/fabric-samples)
- [Chaincode Development Tutorial](https://hyperledger-fabric.readthedocs.io/en/latest/chaincode.html)

### Video Tutorials
- [Hyperledger Fabric Setup](https://www.youtube.com/watch?v=MPNkUqOKhLQ)
- [Smart Contract Development](https://www.youtube.com/watch?v=G3UqWGZkz2I)

### Security Resources
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [OWASP Blockchain Security](https://owasp.org/www-project-smart-contract-security/)

### Community
- [Hyperledger Discord](https://discord.gg/hyperledger)
- [Stack Overflow - Hyperledger](https://stackoverflow.com/questions/tagged/hyperledger-fabric)

---

## 📝 Assignment Submission

### Submission Package Contents
1. ✅ GitHub repository link
2. ✅ Complete source code
3. ✅ Configuration files
4. ✅ Deployment scripts
5. ✅ Simulation results
6. ✅ Screenshots
7. ✅ Security analysis report
8. ✅ README documentation

### Submission Format
Create a Word document: `YourName_RegNum_BT_Assignment4.docx`

Include:
- Your name and registration number
- Assignment title
- GitHub repository link: `https://github.com/yourusername/blockchain-assessment-4`

Convert to PDF and submit via LMS.

---

## 👥 Contributors

**Student Name**: [Your Name]  
**Registration Number**: [Your Reg Number]  
**Course**: ICT4415 - Blockchain Technology  
**Assignment**: Internal Assessment 4

---

## 📄 License

This project is submitted as part of academic coursework for ICT4415 - Blockchain Technology.

---

## 🙏 Acknowledgments

- Hyperledger Fabric Community
- Course Instructor and Teaching Assistants
- Open-source contributors

---

## 📞 Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
3. Contact course instructor
4. Post in course discussion forum

---

**Last Updated**: November 2025  
**Version**: 1.0
