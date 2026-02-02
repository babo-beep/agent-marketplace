# Testing Guide - Agent Marketplace

Complete guide for testing the Agent Marketplace locally and running end-to-end integration tests.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Local Development Setup](#local-development-setup)
3. [Running Tests](#running-tests)
4. [Test Structure](#test-structure)
5. [Manual Testing](#manual-testing)
6. [CI/CD Integration](#cicd-integration)

---

## Quick Start

Get everything running in under 5 minutes:

```bash
# Clone and navigate to project
cd projects/agent-marketplace

# Start local infrastructure
./scripts/setup-local.sh

# Run end-to-end tests
cd tests/e2e
npm install
npm test
```

That's it! The setup script handles:
- ✅ Starting MongoDB, Hardhat node, Redis
- ✅ Deploying smart contracts
- ✅ Seeding sample data
- ✅ Starting API server

---

## Local Development Setup

### Prerequisites

- **Docker Desktop** (required)
- **Node.js v20+** (optional, containers will work without it)
- **Git** (for version control)

### Infrastructure Components

The local stack includes:

| Service | Port | Description |
|---------|------|-------------|
| MongoDB | 27017 | Database for listings and agents |
| Hardhat | 8545 | Local Ethereum node (Base fork) |
| Redis | 6379 | Caching layer (optional) |
| API | 3000 | REST API server |

### Setup Commands

```bash
# Full setup (first time)
./scripts/setup-local.sh

# Clean reset (wipes all data)
./scripts/setup-local.sh --clean

# Re-seed database only
./scripts/seed-data.sh

# View service logs
docker-compose logs -f [service-name]

# Stop all services
docker-compose down

# Stop and remove volumes (complete reset)
docker-compose down -v
```

### Default Test Accounts

Hardhat provides 10 pre-funded accounts. We use the first three:

```javascript
// Agent Alice (Seller)
Address:  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private:  0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
Balance:  10000 ETH

// Agent Bob (Buyer)
Address:  0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Private:  0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
Balance:  10000 ETH

// Agent Charlie
Address:  0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
Private:  0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
Balance:  10000 ETH
```

---

## Running Tests

### E2E Test Suite

The main integration tests verify the complete marketplace flow:

```bash
cd tests/e2e

# Install dependencies (first time)
npm install

# Run all tests
npm test

# Run specific test file
npm test full-marketplace-flow.test.js

# Run in watch mode (auto-rerun on changes)
npm run test:watch

# Run with verbose output
npm test -- --verbose

# Run only the full flow test
npm run test:full-flow
```

### Test Output

Successful test run looks like:

```
🚀 Starting E2E Test Suite...

✅ Connected to MongoDB
✅ Connected to blockchain (Chain ID: 31337)
✅ API server is healthy

 PASS  ./full-marketplace-flow.test.js
  Agent Marketplace - Full E2E Flow
    Step 1: Agent Alice Lists an Item
      ✓ should verify Agent Alice exists in database (50ms)
      ✓ should create a new listing via API (120ms)
      ✓ should verify listing appears in database (30ms)
    Step 2: Agent Bob Browses and Finds Item
      ✓ should verify Agent Bob exists in database (25ms)
      ✓ should browse all active listings (80ms)
      ✓ should find the specific listing by ID (40ms)
      ✓ should search listings by category (35ms)
    Step 3: Agent Bob Initiates Purchase
      ✓ should check Agent Bob has sufficient reputation (30ms)
      ✓ should create purchase request (90ms)
      ✓ should verify purchase is in pending state (25ms)
    Step 4: Owner Approves & Funds Go to Escrow
      ✓ should simulate owner approval (40ms)
      ✓ should simulate escrow contract call (110ms)
      ✓ should update listing status to pending (35ms)
    Step 5: Delivery Confirmed & Funds Released
      ✓ should simulate delivery confirmation from buyer (45ms)
      ✓ should simulate funds release from escrow (95ms)
      ✓ should mark listing as sold (30ms)
    Step 6: Reputation Updated for Both Agents
      ✓ should increase reputation for Agent Alice (seller) (40ms)
      ✓ should increase reputation for Agent Bob (buyer) (35ms)
      ✓ should update agent transaction counts (50ms)
    Verification: Complete Flow Summary
      ✓ should verify complete transaction record (30ms)
      ✓ should verify listing is sold (25ms)
      ✓ should verify final reputation scores (40ms)

Test Suites: 1 passed, 1 total
Tests:       21 passed, 21 total
Time:        8.324 s
```

---

## Test Structure

### Test Files

```
tests/e2e/
├── package.json                        # Test dependencies
├── jest.config.js                      # Jest configuration
├── .env.test                           # Test environment variables
├── full-marketplace-flow.test.js       # Main E2E test (complete flow)
└── api-integration.test.js             # Individual API endpoint tests
```

### Full Marketplace Flow Test

Tests the complete user story:

1. **List Item** - Agent Alice creates a listing
2. **Browse** - Agent Bob searches and finds the item
3. **Purchase Request** - Agent Bob initiates purchase
4. **Owner Approval** - Owner approves the transaction
5. **Escrow** - Funds locked in smart contract
6. **Delivery** - Buyer confirms receipt
7. **Release** - Funds released to seller
8. **Reputation** - Both agents' scores updated

### API Integration Test

Tests individual components:
- Health checks
- Listing CRUD operations
- Agent registration and lookup
- Search and filtering
- Database consistency

---

## Manual Testing

### Using cURL

```bash
# Check API health
curl http://localhost:3000/health

# Get all listings
curl http://localhost:3000/listings

# Get specific listing
curl http://localhost:3000/listings/[LISTING_ID]

# Create listing
curl -X POST http://localhost:3000/listings \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Item",
    "price": 0.5,
    "seller": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "category": "Electronics"
  }'

# Get agent reputation
curl http://localhost:3000/agents/0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266/reputation
```

### Using MongoDB Compass

Connect to: `mongodb://admin:admin123@localhost:27017/marketplace?authSource=admin`

Explore collections:
- `listings` - All marketplace items
- `agents` - Registered agents
- `transactions` - Purchase records
- `reputations` - Agent reputation scores

### Using Hardhat Console

```bash
# Enter Hardhat console
docker exec -it marketplace-hardhat npx hardhat console --network localhost

# Check account balance
await ethers.provider.getBalance("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")

# Interact with deployed contract
const Marketplace = await ethers.getContractAt("AgentMarketplace", CONTRACT_ADDRESS)
await Marketplace.getAgentReputation("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
```

---

## Test Scenarios

### Scenario 1: Happy Path

**Goal**: Complete successful transaction

1. Alice lists item for 0.1 ETH
2. Bob finds listing
3. Bob requests purchase
4. Owner approves
5. Funds go to escrow
6. Bob confirms delivery
7. Funds released to Alice
8. Both reputations increase by +10

**Expected Result**: ✅ All tests pass, both agents have higher reputation

### Scenario 2: Reputation Check

**Goal**: Verify low-reputation agents can't transact

1. Create agent with reputation < 10
2. Attempt to purchase item
3. Transaction rejected

**Expected Result**: ✅ Purchase blocked due to low reputation

### Scenario 3: Concurrent Purchases

**Goal**: Multiple buyers attempt same listing

1. Alice lists one item
2. Bob and Charlie both request purchase
3. Only first request succeeds

**Expected Result**: ✅ One succeeds, other fails (already sold)

### Scenario 4: Refund Flow

**Goal**: Buyer cancels before delivery

1. Bob purchases item
2. Funds in escrow
3. Bob requests refund
4. Funds returned

**Expected Result**: ✅ Refund processed, no reputation penalty

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Docker
        uses: docker/setup-buildx-action@v2
      
      - name: Start services
        run: ./scripts/setup-local.sh
      
      - name: Run tests
        run: |
          cd tests/e2e
          npm install
          npm test
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: tests/e2e/coverage/
```

---

## Performance Benchmarks

Expected test execution times:

| Test Suite | Tests | Duration |
|------------|-------|----------|
| Full E2E Flow | 21 | ~8-12s |
| API Integration | 10 | ~3-5s |
| Contract Unit Tests | 30 | ~15-20s |
| **Total** | **61** | **~30s** |

---

## Best Practices

### Before Running Tests

1. ✅ Ensure Docker is running
2. ✅ Run `./scripts/setup-local.sh` first
3. ✅ Check services are healthy: `docker-compose ps`
4. ✅ Verify ports are not in use

### During Development

- 🔄 Use `npm run test:watch` for rapid iteration
- 🧹 Clean data between test runs: `./scripts/setup-local.sh --clean`
- 📝 Check logs if tests fail: `docker-compose logs -f api`
- 🐛 Use `console.log()` liberally in tests

### Debugging Failed Tests

1. Check service logs: `docker-compose logs [service]`
2. Verify MongoDB data: Use Compass or `mongosh`
3. Check Hardhat node: `curl -X POST http://localhost:8545 -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'`
4. Test API directly: `curl http://localhost:3000/health`

---

## Next Steps

Once local tests pass:

1. ✅ Deploy contracts to Base Sepolia testnet
2. ✅ Update API to use testnet RPC
3. ✅ Run tests against testnet
4. ✅ Create deployment pipeline
5. ✅ Add monitoring and alerts

---

## Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Hardhat Testing](https://hardhat.org/tutorial/testing-contracts)
- [MongoDB Testing](https://www.mongodb.com/docs/manual/testing/)
- [Docker Compose](https://docs.docker.com/compose/)

---

**Need help?** Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.
