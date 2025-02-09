# CentoAI: AI-Powered DeFi Portfolio Manager

![CentoAI Logo](/CentoAI.png)

**CentoAI** is an AI-powered DeFi portfolio manager that optimizes yield farming and flash loan arbitrage across top DeFi protocols like **Aave**, **Compound**, and **Uniswap V3**. Built using **Coinbase AgentKit**, **Privy**, and deployed on **Base** and **Arbitrum**, CentoAI automates fund management and strategy execution to maximize user returns.

---

## 🚀 Features

- **AI-Driven Yield Optimization**: Dynamically reallocates funds to the highest-yielding opportunities across DeFi protocols.
- **Flash Loan Arbitrage**: Executes arbitrage strategies using **Balancer V2** flash loans for risk-free profits.
- **Multi-Protocol Integration**: Supports **Aave**, **Compound**, **Uniswap V3**, and **Balancer V2**.
- **On-Chain Automation**: Uses **Coinbase AgentKit** to automate fund movements and strategy execution.
- **User-Friendly Vaults**: Each user gets a personalized vault to deposit funds and set strategies.
- **Seamless Onboarding**: Leverages **Privy** for embedded wallets and social logins, making it easy for users to onboard and interact with DeFi.
- **Base Deployment**: Deployed on **Base** for low-cost, high-speed transactions.
- **Arbitrum Deployment**: Deployed on **Arbitrum** for low-cost, high-speed transactions.

---

## 🛠️ Tech Stack

- **Core Framework**: [Coinbase AgentKit](https://developer.coinbase.com/agentkit)
- **Onboarding**: [Privy](https://privy.io)
- **Blockchain**: [Base](https://base.org), [Arbitrum](https://arbitrum.io)
- **Frontend**: Next.js + OnchainKit
- **Backend**: Node.js
- **Smart Contracts**: Solidity (Foundry for testing and deployment)

---

## 🏗️ Architecture Overview

CentoAI is built on a modular architecture, with the following key components:

### 1. **Smart Contracts**
   - **LiquidityManager.sol**: Manages liquidity across **Aave**, **Compound**, and **Uniswap V3**.
   - **Arbitrage.sol**: Executes flash loan arbitrage strategies using **Balancer V2**.
   - **Vault.sol**: Manages user balances and strategy execution.
   - **VaultFactory.sol**: Deploys personalized vaults for users.

### 2. **Frontend**
   - Built with **Next.js** and **OnchainKit** for seamless wallet integration and portfolio visualization.
   - Provides a user-friendly dashboard for monitoring portfolio performance and strategy execution.
   - Integrates **Privy** for embedded wallets and social logins, enabling users to onboard with email or existing wallets.

### 3. **Backend**
   - **Node.js** backend for handling off-chain computations and API integrations.
   - Fetches real-time APY data from DeFi protocols and provides it to the AI agent.

### 4. **AI Agent**
   - Analyzes yield opportunities and arbitrage strategies using machine learning models.
   - Executes strategies securely using **Coinbase AgentKit**.

---

## 🔧 Workflows

### 1. **User Onboarding**
   - Users connect their wallets or sign in with email/social login using **Privy**.
   - A personalized vault is deployed for the user using **VaultFactory.sol**.
   - Users deposit ERC20 tokens (e.g., USDC, ETH) into their vault.

### 2. **AI-Driven Strategy Execution**
   - The AI agent fetches real-time APY data from **Aave**, **Compound**, and **Uniswap V3**.
   - It analyzes yield opportunities and identifies arbitrage opportunities using **Balancer V2** flash loans.
   - The AI agent executes strategies such as:
     - **Yield Farming**: Moves funds between protocols to maximize APY.
     - **Flash Loan Arbitrage**: Executes risk-free arbitrage between DEXes.

### 3. **Portfolio Management**
   - Users can monitor their portfolio performance, strategy execution, and transaction history through the dashboard.
   - The dashboard provides insights into:
     - Current APY across protocols.
     - Profit/loss from arbitrage strategies.
     - Historical performance of the portfolio.

---

## 🧩 Smart Contracts

### 1. **LiquidityManager.sol**
   - Manages liquidity across **Aave**, **Compound**, and **Uniswap V3**.
   - Key Functions:
     - `supplyLiquidityOnAave`: Supplies liquidity to Aave.
     - `withdrawLiquidityFromCompound`: Withdraws liquidity from Compound.
     - `swapOnUniswap`: Executes token swaps on Uniswap V3.

### 2. **Arbitrage.sol**
   - Executes flash loan arbitrage strategies using **Balancer V2**.
   - Key Functions:
     - `executeTrade`: Initiates a flash loan and executes arbitrage.
     - `receiveFlashLoan`: Callback function for flash loan execution.

### 3. **Vault.sol**
   - Manages user balances and strategy execution.
   - Key Functions:
     - `depositERC20`: Deposits ERC20 tokens into the vault.
     - `withdrawERC20`: Withdraws ERC20 tokens from the vault.
     - `lendTokens`: Lends tokens to **Aave** or **Compound**.

### 4. **VaultFactory.sol**
   - Deploys personalized vaults for users.
   - Key Functions:
     - `createVault`: Deploys a new vault for a user.
     - `getVaultAddress`: Retrieves the vault address for a user.

---

## 🛠️ Integration Details

### 1. **Coinbase AgentKit**
   - Used for secure, programmatic wallet interactions.
   - Enables the AI agent to execute on-chain actions (e.g., deposits, withdrawals, swaps).

### 2. **Privy**
   - Provides embedded wallets and social logins, making it easy for users to onboard and interact with DeFi.
   - Supports both web3-native users (with existing wallets) and newcomers (with email/social login).

### 3. **Base and Arbitrum**
   - CentoAI is deployed on **Base** and **Arbitrum** for low-cost, high-speed transactions.
   - Supports yield farming and arbitrage strategies on both networks.

---

## 🏆 Sponsor Tracks

CentoAI is designed to compete in the following **ETHGlobal Agentic Ethereum** tracks:

### **Coinbase Developer Platform**
- **Most Innovative Use of AgentKit**: CentoAI uses AgentKit to automate complex DeFi strategies, abstracting away the complexity for users.
- **Best Combination of AgentKit + OnchainKit**: The frontend integrates **OnchainKit** for seamless wallet interactions and portfolio visualization.
- **Viral Consumer App Award**: CentoAI’s user-friendly interface and AI-driven strategies make it accessible to both DeFi experts and beginners.
- **AgentKit Pool Prize**: CentoAI is built with AgentKit in a meaningful way for users to interact with the DeFi ecosystem.

### **Base**
- **Build an AI-Powered App on Base**: CentoAI is deployed on **Base**, leveraging its low-cost, high-speed infrastructure for seamless DeFi operations.

### **Privy**
- **Best Consumer Experience Built with Server Wallets**: CentoAI uses **Privy** to provide a seamless onboarding experience, enabling users to sign in with email, social login, or existing wallets. This makes CentoAI accessible to all users, regardless of their web3 experience.

### **Arbitrum**
- **Most Innovative AI Agent Applications**: CentoAI combines yield farming and flash loan arbitrage to push the boundaries of DeFi automation.

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
    forge script script/DeployVaultFactory.sol:DeployVaultFactory <BASE_SEPOLIA_RPC_URL> --private-key <PRIVATE_KEY> --broadcast --verify --verifier blockscout --verifier-url https://base-sepolia.blockscout.com/api/
    ```

   Deploy the contract to the Arbitrum Sepolia Testnet:
   ```bash
    forge script script/DeployVaultFactory.sol:DeployVaultFactory <ARBITRUM_SEPOLIA_RPC_URL> --private-key <PRIVATE_KEY> --broadcast --verify --verifier blockscout --verifier-url https://arbitrum-sepolia.blockscout.com/api/
    ```


## Testing
Foundry is used for testing the Arbitrage contract. To run the tests:

1. Write your tests in the test directory.

2. Run the tests using:
    ```bash
    forge test
    ```

---

## 🚨 Disclaimer

CentoAI is a proof-of-concept project built for the **ETHGlobal Agentic Ethereum** hackathon. It is not audited and should not be used in production. Use at your own risk.

---

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

---

## 📄 License

This project is licensed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **ETHGlobal** for hosting the **Agentic Ethereum** hackathon.
- **Coinbase**, **Base**, **Privy**, and **Arbitrum** for their support and tooling.
