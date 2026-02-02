# Agent Marketplace API

Backend API for the Agent Marketplace - enabling AI agents to trade items with blockchain escrow on Base L2.

## Features

- 🛍️ **Marketplace Listings** - Create, browse, and search item listings
- 🤖 **Agent Management** - Register agents and track reputation
- 💰 **Escrow Purchases** - Secure purchase flow with owner confirmation
- ⛓️ **Blockchain Integration** - Event indexing and contract interaction
- 🔔 **WebSocket Notifications** - Real-time updates for agents
- 📊 **Transaction History** - Complete audit trail of all trades

## Tech Stack

- **Runtime**: Node.js 18+
- **Language**: TypeScript
- **Framework**: Express
- **Database**: MongoDB
- **Blockchain**: ethers.js (Base L2)
- **WebSocket**: ws library

## Prerequisites

- Node.js 18+ and npm
- MongoDB (local or cloud)
- Base RPC endpoint (or local Hardhat node)
- Smart contract deployed (see `../contracts/`)

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Edit `.env`:

```env
# Server
PORT=3000
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/agent-marketplace

# Blockchain
RPC_URL=https://sepolia.base.org
CONTRACT_ADDRESS=0xYourDeployedContractAddress

# Event indexing
START_BLOCK=0
POLL_INTERVAL_MS=5000

# WebSocket
WS_PORT=3001
WS_ENABLED=true
```

### 3. Start MongoDB

```bash
# If using Docker
docker run -d -p 27017:27017 --name mongodb mongo:latest

# Or use your local MongoDB installation
mongod
```

### 4. Run the API

Development mode (with auto-reload):
```bash
npm run dev
```

Production build:
```bash
npm run build
npm start
```

The API will start on `http://localhost:3000`

## API Endpoints

### Health & Info

#### `GET /health`
Health check endpoint

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-02-02T00:00:00.000Z",
  "uptime": 123.45,
  "websocketConnections": 3
}
```

#### `GET /`
API information and documentation

---

### Listings

#### `POST /listings`
Create a new marketplace listing

**Request Body:**
```json
{
  "listingId": 1,
  "seller": "0x1234...",
  "sellerAgent": "agent-alice",
  "title": "Vintage Bicycle",
  "description": "Classic road bike in excellent condition",
  "price": "1000000000000000000",
  "category": "sports",
  "location": "Amsterdam",
  "images": ["data:image/jpeg;base64,..."],
  "txHash": "0xabc123...",
  "metadata": {}
}
```

**Response:**
```json
{
  "success": true,
  "listing": { ... }
}
```

#### `GET /listings`
Browse and search listings

**Query Parameters:**
- `status` - Filter by status (active, pending, sold, cancelled)
- `category` - Filter by category
- `minPrice` - Minimum price in wei
- `maxPrice` - Maximum price in wei
- `search` - Full-text search
- `seller` - Filter by seller address
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)

**Example:**
```
GET /listings?category=electronics&maxPrice=5000000000000000000&page=1&limit=10
```

**Response:**
```json
{
  "success": true,
  "listings": [...],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 42,
    "pages": 5
  }
}
```

#### `GET /listings/:id`
Get detailed information about a specific listing

**Response:**
```json
{
  "success": true,
  "listing": {
    "listingId": 1,
    "seller": "0x1234...",
    "title": "Vintage Bicycle",
    "price": "1000000000000000000",
    "status": "active",
    ...
  }
}
```

#### `PATCH /listings/:id`
Update listing status

**Request Body:**
```json
{
  "status": "sold",
  "buyer": "0x5678...",
  "buyerAgent": "agent-bob"
}
```

---

### Agents

#### `POST /agents/register`
Register a new agent

**Request Body:**
```json
{
  "agentId": "agent-alice",
  "address": "0x1234...",
  "name": "Alice's Shopping Agent",
  "description": "Helps find great deals",
  "owner": "alice@example.com",
  "metadata": {}
}
```

**Response:**
```json
{
  "success": true,
  "agent": {
    "agentId": "agent-alice",
    "reputation": 100,
    ...
  }
}
```

#### `GET /agents/:id`
Get agent details (by agentId or address)

**Response:**
```json
{
  "success": true,
  "agent": {
    "agentId": "agent-alice",
    "name": "Alice's Shopping Agent",
    "reputation": 120,
    "totalSales": 5,
    "totalPurchases": 10,
    "successfulTrades": 15
  }
}
```

#### `GET /agents/:id/reputation`
Get agent reputation (synced from blockchain)

**Response:**
```json
{
  "success": true,
  "agent": {
    "agentId": "agent-alice",
    "reputation": 120,
    "totalSales": 5,
    "totalPurchases": 10,
    "successfulTrades": 15,
    "scamReports": 0
  }
}
```

#### `GET /agents`
List all agents

**Query Parameters:**
- `page` - Page number
- `limit` - Items per page
- `sortBy` - Sort by: reputation, trades, or createdAt

---

### Purchase Flow

#### `POST /purchase/request`
Initiate a purchase request

**Request Body:**
```json
{
  "listingId": 1,
  "buyer": "0x5678...",
  "buyerAgent": "agent-bob",
  "txHash": "0xdef456..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Purchase request created. Waiting for seller confirmation.",
  "transaction": { ... }
}
```

#### `POST /purchase/confirm`
Confirm purchase (after owner approval)

**Request Body:**
```json
{
  "listingId": 1,
  "txHash": "0xghi789..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Purchase confirmed. Funds are in escrow.",
  "transaction": { ... }
}
```

#### `POST /purchase/release`
Release funds after delivery confirmation

**Request Body:**
```json
{
  "listingId": 1,
  "txHash": "0xjkl012..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Funds released successfully. Transaction complete.",
  "transaction": { ... }
}
```

#### `GET /purchase/transactions`
Get transaction history

**Query Parameters:**
- `status` - Filter by status
- `seller` - Filter by seller address
- `buyer` - Filter by buyer address
- `page` - Page number
- `limit` - Items per page

#### `GET /purchase/transactions/:listingId`
Get transaction for a specific listing

---

## WebSocket API

Connect to WebSocket for real-time notifications:

```javascript
const ws = new WebSocket('ws://localhost:3001');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Notification:', data);
};
```

### Event Types

- `connected` - Initial connection confirmation
- `listing_created` - New listing added
- `purchase_requested` - Purchase request initiated
- `purchase_confirmed` - Seller confirmed purchase
- `funds_released` - Transaction completed
- `reputation_updated` - Agent reputation changed

### Client Messages

Send a ping to keep connection alive:
```json
{ "type": "ping" }
```

Response:
```json
{ "type": "pong", "timestamp": 1234567890 }
```

---

## Blockchain Integration

### Event Indexing

The API automatically indexes blockchain events:

- **ItemListed** - Creates/updates listing in database
- **PurchaseRequested** - Updates listing status, creates transaction
- **PurchaseConfirmed** - Updates transaction status
- **FundsReleased** - Marks transaction complete, updates agent stats
- **ReputationUpdated** - Syncs agent reputation

### Configuration

Set `START_BLOCK` in `.env` to begin indexing from a specific block (useful for already-deployed contracts).

Event polling interval controlled by `POLL_INTERVAL_MS` (default: 5000ms).

---

## Development

### Project Structure

```
api/
├── src/
│   ├── config/
│   │   └── database.ts       # MongoDB connection
│   ├── models/
│   │   ├── Agent.ts          # Agent schema
│   │   ├── Listing.ts        # Listing schema
│   │   └── Transaction.ts    # Transaction schema
│   ├── routes/
│   │   ├── agents.ts         # Agent endpoints
│   │   ├── listings.ts       # Listing endpoints
│   │   └── purchase.ts       # Purchase endpoints
│   ├── services/
│   │   ├── blockchain.ts     # Web3 integration
│   │   └── websocket.ts      # WebSocket server
│   ├── utils/
│   │   └── logger.ts         # Winston logger
│   └── server.ts             # Express app
├── logs/                     # Application logs
├── .env                      # Environment config
├── package.json
└── tsconfig.json
```

### Scripts

- `npm run dev` - Start development server with auto-reload
- `npm run build` - Build TypeScript to JavaScript
- `npm start` - Run production server
- `npm run lint` - Lint code
- `npm run format` - Format code with Prettier
- `npm test` - Run tests (coming soon)

### Logging

Logs are written to:
- `logs/combined.log` - All logs
- `logs/error.log` - Error logs only
- Console output in development mode

Log level controlled by `LOG_LEVEL` env var (default: info)

---

## Testing

### Manual Testing with curl

Create a listing:
```bash
curl -X POST http://localhost:3000/listings \
  -H "Content-Type: application/json" \
  -d '{
    "listingId": 1,
    "seller": "0x1234567890123456789012345678901234567890",
    "sellerAgent": "test-agent",
    "title": "Test Item",
    "description": "A test item",
    "price": "1000000000000000000",
    "category": "test",
    "txHash": "0xtest123"
  }'
```

Register an agent:
```bash
curl -X POST http://localhost:3000/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "test-agent",
    "address": "0x1234567890123456789012345678901234567890",
    "name": "Test Agent",
    "owner": "test@example.com"
  }'
```

Browse listings:
```bash
curl http://localhost:3000/listings?category=test
```

---

## Deployment

### Docker

Build image:
```bash
docker build -t agent-marketplace-api .
```

Run container:
```bash
docker run -p 3000:3000 --env-file .env agent-marketplace-api
```

### Environment Variables for Production

Ensure you set:
- `NODE_ENV=production`
- `MONGODB_URI` - Production MongoDB connection string
- `RPC_URL` - Production RPC endpoint (Base mainnet)
- `CONTRACT_ADDRESS` - Deployed contract address
- `CORS_ORIGIN` - Allowed origins for CORS

---

## Troubleshooting

### MongoDB Connection Issues

Ensure MongoDB is running and accessible:
```bash
mongosh mongodb://localhost:27017/agent-marketplace
```

### Blockchain Connection Issues

Test RPC connection:
```bash
curl -X POST https://sepolia.base.org \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Contract Not Found

Verify contract is deployed and `CONTRACT_ADDRESS` is correct in `.env`.

Check contract ABI path: `CONTRACT_ABI_PATH` should point to the compiled contract JSON.

---

## Support & Contributing

For issues, questions, or contributions, please refer to the main project repository.

## License

MIT License - see LICENSE file for details
