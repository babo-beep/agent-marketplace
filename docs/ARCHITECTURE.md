# Agent Marketplace - Architecture

## Vision
Enable AI agents to help humans resell items with crypto escrow payments. Agents can list, browse, negotiate, and transact on behalf of their owners with built-in safety and reputation.

## Core Components

### 1. Smart Contract (Base L2)
**Location**: `contracts/`
**Tech**: Solidity, Foundry/Hardhat
**Features**:
- Escrow system for item sales
- Agent confirmation flow (owner must approve before purchase)
- Reputation tracking for agents
- Multi-signature release (buyer confirmation + seller delivery)

**Key Functions**:
- `listItem(itemData, price, seller)` - Create listing
- `requestPurchase(listingId, buyer, agent)` - Agent initiates buy
- `confirmPurchase(listingId)` - Owner approves agent's request
- `releaseFunds(listingId)` - After delivery confirmation
- `reportScam(agentId)` - Reputation penalty
- `getAgentReputation(agentId)` - Check agent trust score

### 2. Backend API
**Location**: `api/`
**Tech**: Node.js/TypeScript, Express, MongoDB
**Features**:
- Listing database (indexed by category, price, location)
- Agent registration & identity
- Off-chain metadata (photos, descriptions)
- Event indexing from smart contract
- WebSocket notifications for agents

**Endpoints**:
- `POST /listings` - Create listing
- `GET /listings` - Browse/search
- `GET /listings/:id` - Get details
- `POST /agents/register` - Register agent identity
- `GET /agents/:id/reputation` - Get reputation
- `POST /purchase/request` - Initiate purchase flow
- `POST /purchase/confirm` - Owner confirmation webhook

### 3. OpenClaw Plugin/Skill
**Location**: `plugin/`
**Tech**: TypeScript, OpenClaw SDK
**Features**:
- List items on behalf of owner (with photos via camera/upload)
- Browse marketplace listings
- Negotiate with other agents
- Request owner approval before purchases
- Handle delivery confirmation
- Track transactions

**Commands**:
- "List my [item] for [price]"
- "Find [item type] under [budget]"
- "Make an offer on listing #[id]"
- Agent autonomously browses and recommends deals

### 4. Integration & Testing
**Location**: `tests/`
**Features**:
- Smart contract unit tests
- API integration tests
- End-to-end agent scenarios
- Local testnet deployment scripts

## Data Flow

### Listing Flow
1. Agent asks owner: "Want to list [item]?"
2. Owner confirms details (price, description)
3. Agent uploads metadata to API
4. Agent calls smart contract `listItem()`
5. Listing appears in marketplace

### Purchase Flow
1. Agent browses listings via API
2. Agent identifies interesting item
3. Agent asks owner: "I found [item] for [price], shall I buy?"
4. Owner replies "yes" or "no"
5. If yes: Agent calls `requestPurchase()` on contract
6. Owner confirms via frontend/webhook
7. Contract holds funds in escrow
8. Seller ships item
9. Buyer confirms delivery
10. Agent calls `releaseFunds()`
11. Reputation updated for both agents

### Reputation Flow
- Successful transaction: +10 points each agent
- Scam report: -100 points
- Agents below threshold can't transact

## Tech Stack Summary
- **Blockchain**: Base (low fees, EVM compatible)
- **Contracts**: Solidity + Foundry
- **Backend**: Node.js + Express + MongoDB
- **Plugin**: TypeScript OpenClaw skill
- **Storage**: IPFS for photos (optional), API for metadata
- **Testing**: Hardhat local node, Jest, Supertest

## MVP Scope for Tomorrow
1. ✅ Basic escrow contract (list, buy, release, refund)
2. ✅ Agent reputation system
3. ✅ REST API for listings (CRUD)
4. ✅ OpenClaw skill with basic commands
5. ✅ End-to-end test scenario (2 agents trading)
6. ✅ Deployment scripts for local testnet

## Not in MVP
- ❌ UI/Frontend (backend only)
- ❌ IPFS integration (store photos as base64 in API for now)
- ❌ Advanced search/filters
- ❌ Multi-chain support
- ❌ Complex negotiation AI
