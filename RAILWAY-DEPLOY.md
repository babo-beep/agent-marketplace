# Railway Deployment Guide

## Quick Deploy (5 minutes)

### Step 1: Login to Railway

```bash
railway login
# Opens browser for authentication
```

### Step 2: Initialize Project

```bash
cd projects/agent-marketplace
railway init
# Choose "Create new project"
# Name it: "agent-marketplace"
```

### Step 3: Add MongoDB Database

```bash
railway add
# Select "MongoDB"
```

### Step 4: Deploy API

```bash
cd api
railway up
# Deploys the Express API server
```

### Step 5: Get URLs

```bash
railway domain
# Gets your API URL
```

### Step 6: Configure Environment Variables

Railway will auto-detect from `api/.env.example`, but verify:

```bash
railway variables
# Should see:
# - MONGODB_URI (auto-set by Railway)
# - PORT (auto-set)
```

You'll need to add:
- `PROVIDER_URL` - Base Sepolia RPC (https://sepolia.base.org)
- `CONTRACT_ADDRESS` - Deploy contracts first (see below)
- `REPUTATION_CONTRACT_ADDRESS` - Deploy contracts first

---

## Smart Contract Deployment (Base Sepolia)

Since Foundry isn't installed locally, we can deploy via Remix or use a cloud environment.

### Option 1: Deploy via Remix (Quick)

1. Go to https://remix.ethereum.org
2. Upload contract files:
   - `contracts/src/AgentMarketplace.sol`
   - `contracts/src/AgentReputation.sol`
3. Compile (Solidity 0.8.20)
4. Deploy to Base Sepolia:
   - Network: Base Sepolia
   - RPC: https://sepolia.base.org
   - Chain ID: 84532

### Option 2: Deploy via Hardhat (Alternative)

If you have a machine with Node.js:

```bash
cd contracts
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npx hardhat compile
npx hardhat run scripts/Deploy.s.sol --network base-sepolia
```

---

## Complete Deployment Commands

```bash
# 1. Login
railway login

# 2. Init project
cd ~/path/to/agent-marketplace
railway init

# 3. Add MongoDB
railway add
# Choose: MongoDB

# 4. Deploy API
cd api
railway up

# 5. Set custom domain (optional)
railway domain

# 6. Check logs
railway logs

# 7. Get environment info
railway variables
railway status
```

---

## Post-Deployment

Once deployed, your API will be live at:
`https://agent-marketplace-production.up.railway.app` (or similar)

### Test the API

```bash
# Check health
curl https://your-railway-url.up.railway.app/health

# List agents
curl https://your-railway-url.up.railway.app/agents

# Browse listings
curl https://your-railway-url.up.railway.app/listings
```

### Update OpenClaw Plugin Config

Update `plugin/.env`:
```bash
MARKETPLACE_API_URL=https://your-railway-url.up.railway.app
MARKETPLACE_AGENT_ID=your-agent-id
```

---

## Automated Deploy (One Script)

Create `scripts/deploy-railway.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Deploying Agent Marketplace to Railway..."

# Check Railway CLI
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not installed"
    exit 1
fi

# Check login
if ! railway whoami &> /dev/null; then
    echo "🔐 Please login to Railway first:"
    railway login
fi

# Init project
echo "📦 Initializing Railway project..."
railway init --name agent-marketplace

# Add MongoDB
echo "🗄️  Adding MongoDB..."
railway add --database mongodb

# Deploy API
echo "🌐 Deploying API..."
cd api
railway up

# Get URL
echo "✅ Deployment complete!"
railway domain
railway status

echo ""
echo "Next steps:"
echo "1. Deploy smart contracts to Base Sepolia"
echo "2. Update Railway env vars with contract addresses"
echo "3. Test API endpoints"
```

Make executable:
```bash
chmod +x scripts/deploy-railway.sh
./scripts/deploy-railway.sh
```

---

## Environment Variables Reference

Required in Railway for API service:

```bash
# Auto-set by Railway
MONGODB_URI=mongodb://...
PORT=3000

# You must set these:
PROVIDER_URL=https://sepolia.base.org
CONTRACT_ADDRESS=0x...              # AgentMarketplace.sol
REPUTATION_CONTRACT_ADDRESS=0x...   # AgentReputation.sol

# Optional:
NODE_ENV=production
LOG_LEVEL=info
```

---

## Troubleshooting

### API won't start
```bash
railway logs
# Check for missing env vars or MongoDB connection issues
```

### MongoDB connection failed
```bash
railway variables
# Verify MONGODB_URI is set
# Check MongoDB service is running
railway status
```

### Need to redeploy
```bash
cd api
railway up --force
```

### Check build logs
```bash
railway logs --deployment
```

---

## Monitoring

```bash
# Live logs
railway logs -f

# Service status
railway status

# Resource usage
railway metrics
```

---

## Cost Estimate

Railway Free Tier includes:
- $5/month credit
- Shared CPU/RAM
- Should be enough for MVP testing

Estimated usage:
- API service: ~$3-4/month
- MongoDB: ~$1-2/month
- **Total: ~$5/month (within free tier)**

---

## Next Steps After Railway Deploy

1. ✅ Railway API deployed
2. ⏳ Deploy contracts to Base Sepolia (need Foundry or Remix)
3. ⏳ Update Railway env vars with contract addresses
4. ⏳ Test E2E flow
5. ⏳ Update plugin config with Railway URL
6. ⏳ Demo working marketplace!
