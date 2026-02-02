# Execution Plan - Agent Marketplace MVP

## Timeline: Tonight → Tomorrow Morning
**Deadline**: Ready for testing by ~9:00 AM CET (Feb 2, 2026)

## Parallel Work Streams (Sub-Agents)

### Agent 1: Smart Contract Developer
**Task**: Build Solidity escrow contract on Base
**Deliverables**:
- `contracts/AgentMarketplace.sol` - Main escrow contract
- `contracts/AgentReputation.sol` - Reputation tracking
- `contracts/test/` - Foundry tests
- `contracts/script/Deploy.s.sol` - Deployment script
- `contracts/README.md` - Setup & deployment guide

**Key Requirements**:
- Use Foundry framework
- Deploy to Base Sepolia testnet
- Include events for API indexing
- Owner confirmation flow before purchase
- Reputation penalties for scams

### Agent 2: Backend API Developer  
**Task**: Build Node.js API for listings & agent coordination
**Deliverables**:
- `api/src/server.ts` - Express app
- `api/src/routes/` - Listings, agents, purchases
- `api/src/models/` - MongoDB schemas
- `api/src/services/blockchain.ts` - Contract interaction
- `api/.env.example` - Config template
- `api/README.md` - Setup & API docs

**Key Requirements**:
- TypeScript + Express
- MongoDB for listings storage
- Web3 integration to read contract events
- WebSocket support for agent notifications
- RESTful endpoints per architecture

### Agent 3: OpenClaw Plugin Developer
**Task**: Build skill for agent marketplace interaction
**Deliverables**:
- `plugin/SKILL.md` - Skill documentation
- `plugin/src/marketplace.ts` - Core marketplace logic
- `plugin/src/commands.ts` - Agent commands
- `plugin/scripts/` - Helper scripts (list, browse, buy)
- `plugin/README.md` - Usage guide

**Key Requirements**:
- TypeScript OpenClaw skill format
- Commands: list, browse, buy, check-reputation
- Owner confirmation flow before purchases
- Integration with backend API
- Example scenarios in docs

### Agent 4: Integration & Testing
**Task**: End-to-end testing & deployment scripts
**Deliverables**:
- `tests/e2e/` - Full scenario tests (2 agents trading)
- `scripts/setup-local.sh` - One-command local deployment
- `scripts/seed-data.sh` - Sample listings for testing
- `docker-compose.yml` - Local stack (API, MongoDB, Hardhat node)
- `docs/TESTING.md` - Testing guide

**Key Requirements**:
- Local testnet deployment (Base fork)
- Seed 2 agent identities
- Run complete trade scenario
- Verify escrow, reputation, API sync
- Document results

## Coordination & Dependencies

### Phase 1 (Parallel, 0-2h)
- **Agent 1**: Write & test smart contracts
- **Agent 2**: Build API structure & routes
- **Agent 3**: Build OpenClaw plugin scaffolding
- **Agent 4**: Setup Docker compose, deployment scripts

### Phase 2 (Integration, 2-4h)
- **Agent 2**: Connect API to deployed contracts
- **Agent 3**: Integrate plugin with API
- **Agent 4**: Write E2E tests with real components

### Phase 3 (Testing, 4-6h)
- **Agent 4**: Run full integration tests
- **All**: Fix bugs, update docs
- **Agent 1**: Deploy to Base Sepolia testnet (optional)

## Communication Protocol
- Each agent commits to `projects/agent-marketplace/` repo
- Use git branches: `feat/contracts`, `feat/api`, `feat/plugin`, `feat/tests`
- Status updates every 30min in shared progress log
- Blockers immediately escalated to coordinator (Babo)

## Success Criteria (Tomorrow Morning)
✅ Smart contract deployed to local testnet  
✅ API running and connected to contract  
✅ OpenClaw skill can list/browse/buy items  
✅ E2E test: Agent A lists item, Agent B buys it  
✅ Reputation system works  
✅ All components documented in `/docs`  

## Rollback Plan
If any component fails critically:
- Fall back to mock implementations
- Document what works vs what's stubbed
- Provide clear path to completion

## Post-MVP Enhancements (Not Tonight)
- Frontend UI
- IPFS for photos
- Multi-chain support
- Advanced search
- Automated negotiations
