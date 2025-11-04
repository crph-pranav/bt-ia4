# Blockchain Technology - Internal Assessment 4

## Overview
Solutions for enterprise blockchain implementation and security analysis:
1. Hyperledger Fabric supply chain network
2. Layer 2 blockchain security threat analysis

## Q1: Fabric Supply Chain Network
Three-organization network (Manufacturer, Distributor, Retailer) with role-based access control and complete product lifecycle tracking.

**Setup:**
```bash
cd q1-fabric-supply-chain
./scripts/setup-network.sh
./scripts/install-chaincode.sh
./scripts/simulate-lifecycle.sh
```

## Q2: Security Analysis
Comprehensive threat analysis covering double-spending, Sybil attacks, and smart contract exploits with technical mitigation strategies.

**Analysis:** `q2-security-analysis/security-report.md`

## Structure
```
bt_ia4/
├── q1/    # Fabric network implementation
└── q2/      # Security threat analysis
```# bt-ia4
