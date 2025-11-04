# ii. Threat Modeling Analysis for Layer 2 Blockchain Threats

**Frameworks Used:**
- **STRIDE** (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)
- **Attack Trees** for understanding hierarchical attack paths

| **Threat** | **STRIDE Elements** | **Impact** | **Risk Level** |
|-------------|--------------------|-------------|----------------|
| **Double-Spending** | Spoofing, Tampering, Repudiation | Financial loss, chain instability | **High** |
| **Sybil Attack** | Spoofing, DoS, Elevation of Privilege | Consensus manipulation, data censorship | **High** |
| **Smart Contract Exploit** | Tampering, DoS, Information Disclosure | Direct asset theft, protocol disruption | **Critical** |

### Example: Attack Tree (Double-Spending)
```
Double-Spending Attack
│
├── Exploit Finality Delay
│    ├── Race Condition
│    └── Chain Reorganization (51% control)
│
└── Exploit Consensus Weakness
     ├── Validator Collusion
     └── Fork Manipulation
```

**Conclusion:**  
Threat modeling reveals that most Layer 2 attacks stem from inadequate validation, weak consensus control, and exploitable smart contract logic. Applying STRIDE ensures all threat categories are analyzed systematically.
