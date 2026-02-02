# Agent Marketplace - Test Suite

Comprehensive testing suite for the Agent Marketplace project.

## Quick Start

```bash
# From project root
npm run test:e2e

# Or from this directory
cd tests/e2e
npm install
npm test
```

## Test Structure

```
tests/
├── e2e/                               # End-to-end integration tests
│   ├── package.json                   # Test dependencies
│   ├── jest.config.js                 # Jest configuration
│   ├── .env.test                      # Test environment variables
│   ├── full-marketplace-flow.test.js  # Complete marketplace flow (main test)
│   └── api-integration.test.js        # Individual API tests
├── contracts/                         # Smart contract tests (TODO)
└── README.md                          # This file
```

## Test Scenarios

### Full Marketplace Flow (`full-marketplace-flow.test.js`)

Tests the complete user journey:

1. ✅ **List Item** - Agent Alice creates a listing
2. ✅ **Browse** - Agent Bob searches and finds items
3. ✅ **Purchase Request** - Agent Bob requests to buy
4. ✅ **Owner Approval** - Owner confirms the purchase
5. ✅ **Escrow** - Funds locked in smart contract
6. ✅ **Delivery** - Buyer confirms receipt
7. ✅ **Release Funds** - Seller receives payment
8. ✅ **Reputation Update** - Both agents' scores increase

**Run:** `npm run test:full-flow`

### API Integration (`api-integration.test.js`)

Tests individual API endpoints:

- Health checks
- Listing operations (CRUD)
- Agent lookups
- Search and filtering
- Database consistency

**Run:** `npm test api-integration.test.js`

## Prerequisites

Before running tests:

```bash
# Start local infrastructure
cd ../..  # Back to project root
./scripts/setup-local.sh
```

This starts:
- MongoDB (port 27017)
- Hardhat node (port 8545)
- Redis (port 6379)
- API server (port 3000)

## Environment Variables

Test configuration in `.env.test`:

```bash
API_URL=http://localhost:3000
RPC_URL=http://localhost:8545
MONGODB_URI=mongodb://admin:admin123@localhost:27017/marketplace?authSource=admin
CHAIN_ID=31337

# Test accounts (Hardhat defaults)
AGENT_ALICE_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
AGENT_BOB_ADDRESS=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

## Running Tests

### All Tests

```bash
npm test
```

### Specific Test File

```bash
npm test full-marketplace-flow.test.js
```

### Watch Mode (auto-rerun)

```bash
npm run test:watch
```

### With Coverage

```bash
npm test -- --coverage
```

### Verbose Output

```bash
npm test -- --verbose
```

## Test Output

Successful run:

```
 PASS  ./full-marketplace-flow.test.js
  Agent Marketplace - Full E2E Flow
    Step 1: Agent Alice Lists an Item
      ✓ should verify Agent Alice exists in database
      ✓ should create a new listing via API
      ✓ should verify listing appears in database
    ...
    
Test Suites: 1 passed, 1 total
Tests:       21 passed, 21 total
Time:        8.324 s
```

## Debugging Failed Tests

1. **Check service logs:**
   ```bash
   docker-compose logs -f [service]
   ```

2. **Verify services are running:**
   ```bash
   docker-compose ps
   ```

3. **Test individual components:**
   ```bash
   curl http://localhost:3000/health  # API
   docker exec marketplace-mongodb mongosh --eval "db.runCommand('ping')"  # MongoDB
   ```

4. **Reset environment:**
   ```bash
   cd ../..
   ./scripts/setup-local.sh --clean
   ```

## Writing New Tests

Example test structure:

```javascript
const axios = require('axios');
const { MongoClient } = require('mongodb');
require('dotenv').config({ path: '.env.test' });

describe('My Test Suite', () => {
  let db;
  
  beforeAll(async () => {
    // Setup
    const client = new MongoClient(process.env.MONGODB_URI);
    await client.connect();
    db = client.db('marketplace');
  });
  
  it('should test something', async () => {
    // Test logic
    const result = await db.collection('listings').findOne();
    expect(result).toBeTruthy();
  });
  
  afterAll(async () => {
    // Cleanup
  });
});
```

## Common Issues

### Tests timeout

Increase timeout in `jest.config.js`:
```javascript
testTimeout: 120000  // 2 minutes
```

### Connection refused

Services not running. Run:
```bash
./scripts/setup-local.sh
```

### Database inconsistencies

Reset data:
```bash
./scripts/seed-data.sh
```

## CI/CD Integration

Tests run automatically in CI pipeline:

```yaml
- name: Run E2E Tests
  run: |
    ./scripts/setup-local.sh
    cd tests/e2e
    npm install
    npm test
```

## Performance

Expected execution times:

| Test Suite | Duration |
|------------|----------|
| Full E2E Flow | 8-12s |
| API Integration | 3-5s |
| Total | ~15s |

## Resources

- [Jest Documentation](https://jestjs.io/)
- [Testing Guide](../../docs/TESTING.md)
- [Troubleshooting](../../docs/TROUBLESHOOTING.md)

---

For more detailed information, see [docs/TESTING.md](../../docs/TESTING.md)
