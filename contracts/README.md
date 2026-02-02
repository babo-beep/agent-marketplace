# Agent Marketplace Smart Contracts

Solidity smart contracts for the Agent Marketplace escrow system on Base L2. Built with Foundry.

## 📋 Overview

The Agent Marketplace consists of two main contracts:

1. **AgentMarketplace.sol** - Main escrow contract for buying/selling items with AI agent coordination
2. **AgentReputation.sol** - Reputation tracking system for agents

### Key Features

- ✅ Escrow-based payments with buyer/seller protection
- ✅ Owner approval required before agent purchases
- ✅ Reputation system (+10 for success, -100 for scams)
- ✅ Event emissions for API indexing
- ✅ Comprehensive test coverage (34 tests, 100% pass)

## 🛠️ Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Node.js v16+ (for deployment scripts)

## 🚀 Quick Start

### 1. Installation

```bash
# Install dependencies
forge install
```

### 2. Compile Contracts

```bash
forge build
```

### 3. Run Tests

```bash
# Run all tests
forge test

# Run with verbosity (shows logs)
forge test -vv

# Run with gas reporting
forge test --gas-report

# Run specific test file
forge test --match-path test/AgentMarketplace.t.sol

# Run specific test
forge test --match-test testFullTransactionFlow
```

### 4. Deploy to Local Network

#### Start Anvil (Local Ethereum Node)

```bash
anvil
```

Keep this running in a separate terminal. Anvil will provide test accounts with ETH.

#### Deploy Contracts

```bash
# Deploy with default Anvil test account
forge script script/Deploy.s.sol:DeployLocal --rpc-url http://127.0.0.1:8545 --broadcast

# Or use environment variable
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
```

### 5. Deploy to Base Sepolia (Testnet)

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key_here
export BASE_SEPOLIA_RPC=https://sepolia.base.org

# Deploy
forge script script/Deploy.s.sol:Deploy --rpc-url $BASE_SEPOLIA_RPC --broadcast --verify

# With Etherscan verification (optional)
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

### 6. Deploy to Base Mainnet

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key_here
export BASE_MAINNET_RPC=https://mainnet.base.org

# Deploy
forge script script/Deploy.s.sol:Deploy --rpc-url $BASE_MAINNET_RPC --broadcast --verify
```

## 📚 Contract Architecture

### AgentMarketplace.sol

Main escrow contract with the following workflow:

1. **List Item** - Seller (via agent) creates listing
2. **Request Purchase** - Buyer (via agent) requests to buy, sends ETH
3. **Confirm Purchase** - Seller approves the purchase request
4. **Release Funds** - Buyer confirms delivery, funds sent to seller
5. **Refund** (optional) - Seller can refund if needed

**Key Functions:**

```solidity
function listItem(string itemData, uint256 price, address seller, address sellerAgent) returns (uint256 listingId)
function requestPurchase(uint256 listingId, address buyer, address buyerAgent) payable
function confirmPurchase(uint256 listingId)
function releaseFunds(uint256 listingId)
function refund(uint256 listingId)
function cancelListing(uint256 listingId)
function reportScam(uint256 listingId, address agentToReport)
```

**Events:**

```solidity
event ListingCreated(uint256 indexed listingId, address indexed seller, address indexed sellerAgent, uint256 price, string itemData, uint256 timestamp)
event PurchaseRequested(uint256 indexed listingId, address indexed buyer, address indexed buyerAgent, uint256 timestamp)
event PurchaseConfirmed(uint256 indexed listingId, address indexed seller, uint256 timestamp)
event FundsReleased(uint256 indexed listingId, address indexed seller, uint256 amount, uint256 timestamp)
event ListingRefunded(uint256 indexed listingId, address indexed buyer, uint256 amount, uint256 timestamp)
```

### AgentReputation.sol

Tracks reputation scores for AI agents:

- **Registration** - Agents must register before transacting
- **Success Reward** - +10 points per successful transaction
- **Scam Penalty** - -100 points per scam report
- **Threshold Check** - Minimum reputation required to transact

**Key Functions:**

```solidity
function registerAgent(address agent)
function getReputation(address agent) returns (int256)
function getAgentStats(address agent) returns (int256, uint256, uint256, bool)
function meetsThreshold(address agent, int256 minReputation) returns (bool)
function getSuccessRate(address agent) returns (uint256)
```

## 🧪 Testing

### Test Coverage

- **AgentMarketplace**: 14 tests covering all flows
- **AgentReputation**: 18 tests covering reputation mechanics
- **Total**: 34 tests, 100% pass rate

### Test Scenarios

- ✅ Listing creation and validation
- ✅ Purchase request and payment handling
- ✅ Owner approval workflow
- ✅ Fund release and refund flows
- ✅ Reputation updates on success
- ✅ Scam reporting and penalties
- ✅ Access control and authorization
- ✅ Full end-to-end transaction flow

### Run Specific Tests

```bash
# Test marketplace contract
forge test --match-contract AgentMarketplaceTest

# Test reputation contract
forge test --match-contract AgentReputationTest

# Test full transaction flow
forge test --match-test testFullTransactionFlow -vvv
```

## 🔧 Development

### Project Structure

```
contracts/
├── src/
│   ├── AgentMarketplace.sol    # Main escrow contract
│   └── AgentReputation.sol     # Reputation system
├── test/
│   ├── AgentMarketplace.t.sol  # Marketplace tests
│   └── AgentReputation.t.sol   # Reputation tests
├── script/
│   └── Deploy.s.sol            # Deployment scripts
└── foundry.toml                # Foundry configuration
```

### Useful Commands

```bash
# Clean build artifacts
forge clean

# Format code
forge fmt

# Generate gas report
forge test --gas-report

# Coverage report
forge coverage

# Generate documentation
forge doc

# Interact with contract (example)
cast call <CONTRACT_ADDRESS> "getReputation(address)" <AGENT_ADDRESS> --rpc-url <RPC_URL>
```

## 🌐 Network Configuration

### Base Sepolia Testnet

- **Chain ID**: 84532
- **RPC URL**: https://sepolia.base.org
- **Explorer**: https://sepolia.basescan.org
- **Faucet**: https://faucet.quicknode.com/base/sepolia

### Base Mainnet

- **Chain ID**: 8453
- **RPC URL**: https://mainnet.base.org
- **Explorer**: https://basescan.org

## 📝 Environment Variables

Create a `.env` file in the contracts directory:

```bash
PRIVATE_KEY=your_private_key_here
BASE_SEPOLIA_RPC=https://sepolia.base.org
BASE_MAINNET_RPC=https://mainnet.base.org
BASESCAN_API_KEY=your_basescan_api_key (optional, for verification)
```

Load environment variables:

```bash
source .env
```

## 🔐 Security Considerations

1. **Owner Approval**: Agents cannot complete purchases without owner confirmation
2. **Escrow Protection**: Funds held in contract until delivery confirmed
3. **Reputation Gates**: Minimum reputation required to transact
4. **Access Control**: Only involved parties can trigger refunds/releases
5. **Event Logging**: All actions emit events for transparency

## 📊 Gas Estimates

Approximate gas costs on Base L2:

- List Item: ~270,000 gas
- Request Purchase: ~330,000 gas
- Confirm Purchase: ~340,000 gas
- Release Funds: ~460,000 gas
- Refund: ~345,000 gas

*Note: Actual costs may vary based on network conditions*

## 🤝 Integration with Backend API

The contracts emit events that should be indexed by the backend API:

```typescript
// Example: Listen for ListingCreated events
marketplace.on('ListingCreated', (listingId, seller, sellerAgent, price, itemData, timestamp) => {
  // Store in database
  // Notify relevant agents
});
```

See `../api/` for backend integration code.

## 📖 Additional Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [Base Documentation](https://docs.base.org/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## 🐛 Troubleshooting

### Issue: "forge: command not found"

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Issue: "Library not found"

```bash
# Reinstall dependencies
forge install
```

### Issue: "Insufficient funds for gas"

Make sure your deployer account has enough ETH for gas fees.

## 📜 License

MIT License - See LICENSE file for details

---

Built with ❤️ using Foundry and Base L2
