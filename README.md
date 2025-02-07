# CentoAI: AI-Powered DeFi Portfolio Manager

![CentoAI Logo](https://via.placeholder.com/150) <!-- Replace with logo -->

CentoAI is an AI-powered DeFi portfolio manager that optimizes yield farming by dynamically reallocating funds across top DeFi protocols. Built using **Coinbase AgentKit**, **Warden Protocol**, and **Lit Protocol**, CentoAI automates strategy execution securely on **Base** for maximum yield efficiency.

---

## 🚀 Features

- **AI-Driven Yield Optimization**: Dynamically reallocates funds to the highest-yielding opportunities across DeFi protocols like Aave, Compound, and Uniswap.
- **On-Chain Automation**: Uses **Warden Protocol** to automate fund movements based on real-time APY data.
- **Secure Execution**: Leverages **Lit Protocol** for secure transaction signing and non-custodial key management.
- **Base Deployment**: Deployed on **Base** for low-cost, high-speed transactions.
- **User-Friendly Interface**: Built with **OnchainKit** for seamless wallet integration and portfolio management.

---

## 🛠️ Tech Stack

- **Core Framework**: [Coinbase AgentKit](https://developer.coinbase.com/agentkit)
- **Automation**: [Warden Protocol](https://wardenprotocol.org)
- **Security**: [Lit Protocol](https://litprotocol.com)
- **Blockchain**: [Base](https://base.org)
- **Frontend**: React + OnchainKit
- **Backend**: Node.js

---

## 📊 How It Works

1. **Data Aggregation**:  
   - Fetch real-time APY data from DeFi protocols (e.g., Aave, Compound, Uniswap).  
   - Use **Warden Protocol** to monitor and analyze yield opportunities.

2. **AI Decision Engine**:  
   - Analyze yield opportunities using machine learning models.  
   - Determine optimal fund reallocation based on risk-adjusted returns.

3. **Secure Execution**:  
   - **Lit Protocol** enforces policies (e.g., "only execute if APY > X%").  
   - **Coinbase AgentKit** handles on-chain actions (e.g., deposits, withdrawals, swaps).

4. **User Interface**:  
   - A dashboard displays portfolio performance, strategy configurations, and transaction history.  
   - Built with **React** and **OnchainKit** for seamless wallet integration.

---

## 🏆 Sponsor Tracks

CentoAI is designed to compete in the following **ETHGlobal Agentic Ethereum** tracks:

### 🟩 Core Tracks
1. **Coinbase Developer Platform**  
   - Most Innovative Use of AgentKit  
   - Best Combination of AgentKit + OnchainKit  
   - Viral Consumer App Award  
   - AgentKit Pool Prize  

2. **Base**  
   - Build an AI-Powered App on Base  

3. **Lit Protocol**  
   - Best DeFAI Agent  
   - Most Creative Integration  
   - Pool Prize  

4. **Warden Protocol**  
   - Best Use of Warden Protocol for On-Chain Automation  

---

## 🚨 Disclaimer

CentoAI is a proof-of-concept project built for the ETHGlobal Agentic Ethereum hackathon. It is not audited and should not be used in production. Use at your own risk.

---

## 📂 Repository Structure
```
contracts/
    ├── lib/ # Dependencies
    ├── scripts/ # Deployment and utility scripts
    ├── src/ # Smart contracts for onchain actions
    ├── test/ # Unit & Forked Tests of Smart contracts
    ├── scripts/ # Deployment and utility scripts
    ├── README.md # This file
    └── LICENSE # MIT License
```

## Setup Instructions

### Prerequisites

1. **Foundry**: Install Foundry for smart contract development and testing.
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Cento-AI/contracts
   cd cento-ai
   ```

2. Install dependencies:
    ```bash
    forge install
    ```

3. Compile the smart contract:
    ```bash
    forge build
    ```

4. Deploy the contract to the Base Sepolia Testnet:
    ```bash
    forge script script/DeployArbitrage.s.sol:DeployArbitrage <BASE_SEPOLIA_RPC_URL> --private-key <PRIVATE_KEY> --broadcast --verify --verifier blockscout --verifier-url https://base-sepolia.blockscout.com/api/
    ```
   ```bash
    forge script script/DeployLiquidityManager.sol:DeployLiquidityManager <BASE_SEPOLIA_RPC_URL> --private-key <PRIVATE_KEY> --broadcast --verify --verifier blockscout --verifier-url https://base-sepolia.blockscout.com/api/
    ```
   ```bash
    forge script script/DeployLiquidityManager.sol:DeployLiquidityManager <BASE_SEPOLIA_RPC_URL> --private-key <PRIVATE_KEY> --broadcast --verify --verifier blockscout --verifier-url https://base-sepolia.blockscout.com/api/
    ```

## Testing
Foundry is used for testing the Arbitrage contract. To run the tests:

1. Write your tests in the test directory.

2. Run the tests using:
    ```bash
    forge test
    ```

## 🤝 Contributing
Contributions are welcome! Please open an issue or submit a pull request.

## 📄 License
This project is licensed under the MIT License. See LICENSE for details.

## 🙏 Acknowledgments
ETHGlobal for hosting the Agentic Ethereum hackathon.

Coinbase, Base, Lit Protocol, and Warden Protocol for their support and tooling.