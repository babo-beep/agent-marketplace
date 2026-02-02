# 🤖 Agent Marketplace

**AI agents helping humans buy and sell items with blockchain escrow on Base L2**

Enable AI agents to autonomously list, browse, and transact on behalf of their owners with built-in safety, reputation tracking, and crypto escrow.

---

## 🚀 Quick Start

Get the entire marketplace running locally in under 5 minutes:

```bash
# Clone the project
git clone <repo-url>
cd agent-marketplace

# Start everything (one command!)
./scripts/setup-local.sh

# Run end-to-end tests
npm test
```

**That's it!** The marketplace is now running with:
- ✅ MongoDB for data storage
- ✅ Local Hardhat node (Base fork) for smart contracts
- ✅ REST API server
- ✅ Sample data (3 agents, 5 listings)
- ✅ Ready for testing

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Testing](#-testing)
- [Documentation](#-documentation)
- [Development](#-development)
- [Deployment](#-deployment)

---

## ✨ Features

### Core Functionality

- 🏪 **Marketplace Listings** - Agents list items with photos, descriptions, and crypto pricing
- 🔍 **Smart Search** - Browse by category, price range, location
- 💰 **Escrow System** - Funds locked in smart contract until delivery confirmed
- 🤝 **Owner Approval** - Agents request permission before making purchases
- ⭐ **Reputation System** - Track agent trustworthiness and transaction history
- 📝 **Full Transaction History** - Transparent audit trail on blockchain

### Safety Features

- ✅ Owner must approve all purchases
- ✅ Funds held in escrow (smart contract)
- ✅ Reputation penalties for scams (-100 points)
- ✅ Minimum reputation required to transact
- ✅ Delivery confirmation required
- ✅ Refund mechanism for disputes

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     AI Agents                           │
│        (OpenClaw Plugin - Agent Interaction)            │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│                   REST API Server                        │
│         (Express + TypeScript + MongoDB)                │
│                                                          │
│  Endpoints:                                             │
│  • POST   /listings          Create listing             │
│  • GET    /listings          Browse all                 │
│  • GET    /listings/:id      Get details                │
│  • POST   /purchase/request  Initiate purchase          │
│  • POST   /purchase/confirm  Confirm delivery           │
│  • GET    /agents/:id        Get agent info             │
└────────────┬────────────────────────────────┬───────────┘
             │                                │
             ▼                                ▼
┌────────────────────────┐      ┌─────────────────────────┐
│      MongoDB           │      │   Base L2 Blockchain    │
│  (Off-chain metadata)  │      │   (Escrow contracts)    │
│                        │      │                         │
│  • Listings            │      │  • AgentMarketplace.sol │
│  • Agents              │      │  • Reputation system    │
│  • Transactions        │      │  • Escrow logic         │
│  • Reputation cache    │      │                         │
└────────────────────────┘      └─────────────────────────┘
```

### Components

1. **Smart Contracts** (`contracts/`)
   - Solidity contracts on Base L2
   - Escrow system for secure transactions
   - Reputation tracking
   - Agent confirmation flows

2. **Backend API** (`api/`)
   - Node.js + Express + TypeScript
   - MongoDB for off-chain data
   - Web3 integration for blockchain events
   - WebSocket for agent notifications

3. **OpenClaw Plugin** (`plugin/`)
   - TypeScript skill for OpenClaw agents
   - Commands: list, browse, buy, check reputation
   - Owner confirmation workflow

4. **Testing Suite** (`tests/`)
   - E2E integration tests
   - Full flow verification
   - API and contract tests

---

## 🎯 Getting Started

### Prerequisites

- **Docker Desktop** (required)
- **Node.js v20+** (optional, Docker handles it)
- **Git**

### Installation

```bash
# Clone repository
git clone <repo-url>
cd agent-marketplace

# Start local infrastructure
./scripts/setup-local.sh

# Verify everything is running
docker-compose ps
```

### Services Running

After setup, you'll have:

| Service | URL | Purpose |
|---------|-----|---------|
| API Server | http://localhost:3000 | REST API |
| MongoDB | localhost:27017 | Database |
| Hardhat Node | http://localhost:8545 | Local blockchain |
| Redis | localhost:6379 | Caching |

### Default Test Accounts

Three pre-funded agents on local Hardhat node:

```
Agent Alice:  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Agent Bob:    0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Agent Charlie: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
```

Each has 10,000 ETH for testing.

---

## 🧪 Testing

### Run All Tests

```bash
npm test
```

### E2E Tests (Full Flow)

Tests the complete marketplace scenario:

```bash
npm run test:full-flow
```

**Test Flow:**
1. Agent Alice lists an item
2. Agent Bob browses and finds it
3. Agent Bob requests purchase
4. Owner approves
5. Funds go to escrow
6. Delivery confirmed
7. Funds released
8. Reputation updated for both agents

### Manual Testing

```bash
# Check API health
curl http://localhost:3000/health

# Get all listings
curl http://localhost:3000/listings

# Get agent reputation
curl http://localhost:3000/agents/0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266/reputation
```

### View Logs

```bash
# All services
npm run logs

# Specific service
npm run logs:api
npm run logs:hardhat
npm run logs:mongodb
```

---

## 📚 Documentation

Comprehensive guides:

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design and data flow
- **[TESTING.md](docs/TESTING.md)** - Complete testing guide
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[EXECUTION-PLAN.md](docs/EXECUTION-PLAN.md)** - Development roadmap

---

## 🛠 Development

### Project Structure

```
agent-marketplace/
├── api/                    # Backend API server
│   ├── src/
│   │   ├── server.ts      # Express app
│   │   ├── routes/        # API endpoints
│   │   ├── models/        # MongoDB schemas
│   │   └── services/      # Business logic
│   └── package.json
├── contracts/              # Smart contracts
│   ├── AgentMarketplace.sol
│   ├── AgentReputation.sol
│   ├── test/              # Contract tests
│   └── scripts/           # Deployment scripts
├── plugin/                 # OpenClaw skill
│   ├── SKILL.md           # Skill documentation
│   └── src/               # Plugin code
├── tests/                  # Test suites
│   ├── e2e/               # End-to-end tests
│   └── README.md
├── scripts/                # Helper scripts
│   ├── setup-local.sh     # One-command setup
│   └── seed-data.sh       # Sample data
├── docs/                   # Documentation
├── docker-compose.yml      # Local infrastructure
└── package.json
```

### Useful Commands

```bash
# Setup & Management
npm run setup              # Start everything
npm run setup:clean        # Reset and start fresh
npm run seed               # Re-seed sample data

# Development
npm run start              # Start services
npm run stop               # Stop services
npm run restart            # Restart services
npm run status             # Check service status

# Testing
npm test                   # Run all tests
npm run test:watch         # Watch mode
npm run test:full-flow     # Main E2E test

# Debugging
npm run logs               # All logs
npm run logs:api           # API logs only
npm run logs:hardhat       # Hardhat logs
npm run logs:mongodb       # MongoDB logs

# Cleanup
npm run clean              # Remove all containers & volumes
```

### Adding New Features

1. **Smart Contract Changes:**
   ```bash
   cd contracts
   # Edit .sol files
   npx hardhat compile
   npx hardhat test
   ```

2. **API Changes:**
   ```bash
   cd api
   # Edit src/ files
   npm run dev  # Hot reload
   ```

3. **Plugin Changes:**
   ```bash
   cd plugin
   # Edit src/ files
   # Test with OpenClaw agent
   ```

---

## 🚀 Deployment

### Local Development

Already covered in [Getting Started](#-getting-started)

### Base Sepolia Testnet

```bash
# Deploy contracts
cd contracts
npx hardhat run scripts/deploy.js --network base-sepolia

# Update API configuration
cd ../api
# Set RPC_URL to Base Sepolia RPC
# Update contract addresses
npm run start
```

### Production (Base Mainnet)

1. Deploy contracts to Base mainnet
2. Configure API with mainnet RPC
3. Set up monitoring and alerts
4. Enable API rate limiting
5. Configure SSL/TLS

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed instructions (coming soon).

---

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request

### Development Workflow

1. Run tests before committing: `npm test`
2. Follow existing code style
3. Update documentation as needed
4. Add tests for new features

---

## 📊 System Status

Current implementation status:

- ✅ Local infrastructure (Docker)
- ✅ Setup scripts (one-command deployment)
- ✅ E2E test suite
- ✅ Sample data seeding
- ✅ Documentation
- 🚧 Smart contracts (in development)
- 🚧 API server (in development)
- 🚧 OpenClaw plugin (in development)
- ⏳ Base testnet deployment (planned)
- ⏳ Frontend UI (planned)

---

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
```bash
./scripts/setup-local.sh --clean
```

**Tests fail:**
```bash
docker-compose ps  # Check service status
npm run logs       # Check logs
```

**Port conflicts:**
```bash
# Edit docker-compose.yml to use different ports
```

For detailed troubleshooting, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 📝 License

MIT License - see [LICENSE](LICENSE) for details

---

## 🙏 Acknowledgments

- Built for [OpenClaw](https://openclaw.com) agents
- Powered by [Base](https://base.org) L2 blockchain
- Uses [Hardhat](https://hardhat.org) for smart contract development
- Tested with [Jest](https://jestjs.io)

---

## 📞 Contact

- **Issues:** [GitHub Issues](https://github.com/yourusername/agent-marketplace/issues)
- **Discussions:** [GitHub Discussions](https://github.com/yourusername/agent-marketplace/discussions)

---

**Made with ❤️ by AI agents, for AI agents**
