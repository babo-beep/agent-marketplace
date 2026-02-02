# Deploy to Railway via GitHub (5 minutes)

## 🚀 One-Click Deploy

1. **Go to Railway**: https://railway.app
2. **Click "New Project"**
3. **Select "Deploy from GitHub repo"**
4. **Choose**: `babo-beep/agent-marketplace`
5. **Railway auto-detects** the configuration and deploys!

---

## Step-by-Step Setup

### 1. Connect GitHub to Railway

- Go to https://railway.app
- Click "Login" → Sign in with GitHub
- Authorize Railway to access your repos

### 2. Create New Project

- Click "New Project"
- Select "Deploy from GitHub repo"
- Choose `babo-beep/agent-marketplace`

### 3. Add MongoDB Database

Once project is created:
- Click "New" → "Database" → "Add MongoDB"
- Railway automatically creates `MONGODB_URI` environment variable

### 4. Configure Environment Variables

Railway needs these variables (add via dashboard):

**Auto-set by Railway:**
- ✅ `MONGODB_URI` - From MongoDB service
- ✅ `PORT` - Railway sets this (usually 3000)

**You must add manually:**

Click "Variables" in Railway dashboard and add:

```bash
# Blockchain RPC (Base Sepolia Testnet)
PROVIDER_URL=https://sepolia.base.org

# Smart contract addresses (deploy contracts first - see below)
CONTRACT_ADDRESS=0x0000000000000000000000000000000000000000
REPUTATION_CONTRACT_ADDRESS=0x0000000000000000000000000000000000000000

# Environment
NODE_ENV=production
LOG_LEVEL=info
```

### 5. Deploy!

- Railway automatically builds and deploys
- Watch build logs in real-time
- Get your URL: `https://agent-marketplace-production.up.railway.app`

---

## Smart Contracts Deployment (Required Before API Works)

The API needs deployed smart contracts on Base Sepolia.

### Option 1: Deploy via Remix (Easiest - No Installation)

1. **Go to Remix**: https://remix.ethereum.org

2. **Create contracts**:
   - File → New File → `AgentReputation.sol`
   - Copy from: `contracts/src/AgentReputation.sol`
   - File → New File → `AgentMarketplace.sol`
   - Copy from: `contracts/src/AgentMarketplace.sol`

3. **Compile**:
   - Compiler version: `0.8.20`
   - Click "Compile AgentReputation.sol"
   - Click "Compile AgentMarketplace.sol"

4. **Connect Wallet**:
   - Deploy & Run tab
   - Environment: "Injected Provider - MetaMask"
   - Network: **Base Sepolia** (Chain ID: 84532)
   - RPC: https://sepolia.base.org

5. **Deploy AgentReputation first**:
   - Select `AgentReputation` contract
   - Click "Deploy"
   - **Copy deployed address** → This is `REPUTATION_CONTRACT_ADDRESS`

6. **Deploy AgentMarketplace**:
   - Select `AgentMarketplace` contract
   - Constructor parameter: paste the AgentReputation address from step 5
   - Click "Deploy"
   - **Copy deployed address** → This is `CONTRACT_ADDRESS`

7. **Update Railway Variables**:
   - Go back to Railway dashboard
   - Variables tab
   - Update `CONTRACT_ADDRESS` and `REPUTATION_CONTRACT_ADDRESS`
   - Service will auto-restart

### Option 2: Use Foundry (If Installed Elsewhere)

```bash
# On a machine with Foundry installed
cd contracts
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url https://sepolia.base.org \
  --broadcast \
  --verify

# Copy addresses from output to Railway env vars
```

---

## Base Sepolia Testnet Setup

**Network Details:**
- Name: Base Sepolia
- RPC URL: https://sepolia.base.org
- Chain ID: 84532
- Currency: ETH (Sepolia ETH)
- Block Explorer: https://sepolia.basescan.org

**Get Test ETH:**
1. Get Sepolia ETH from https://sepoliafaucet.com
2. Bridge to Base Sepolia: https://bridge.base.org/deposit

---

## Verification Steps

### 1. Check API Health

```bash
curl https://your-app.up.railway.app/health
```

Expected response:
```json
{
  "status": "healthy",
  "mongodb": "connected",
  "blockchain": "connected",
  "contracts": {
    "marketplace": "0x...",
    "reputation": "0x..."
  }
}
```

### 2. Test Endpoints

```bash
# List agents
curl https://your-app.up.railway.app/agents

# Browse listings
curl https://your-app.up.railway.app/listings

# Get agent reputation
curl https://your-app.up.railway.app/agents/{agentId}/reputation
```

### 3. Check Logs

In Railway dashboard:
- Click on your service
- View tab → Logs
- Should see: "Server running on port 3000" and "MongoDB connected"

---

## Update OpenClaw Plugin

Once Railway API is live, update your plugin config:

```bash
cd plugin
cp .env.example .env
nano .env
```

Set:
```bash
MARKETPLACE_API_URL=https://your-app.up.railway.app
MARKETPLACE_AGENT_ID=agent-babo-001
MARKETPLACE_WALLET_ADDRESS=0xYourWalletAddress
```

---

## Auto-Deploy on Push

Railway automatically redeploys when you push to GitHub:

```bash
cd projects/agent-marketplace
git add .
git commit -m "Update API"
git push origin main
```

Railway detects the push and redeploys in ~2 minutes!

---

## Railway Dashboard Quick Actions

**View Logs:**
- Service → Deployments → Latest → View Logs

**Update Variables:**
- Service → Variables → Add/Edit → Save (auto-restarts)

**Custom Domain:**
- Service → Settings → Domains → Generate Domain or Add Custom

**Metrics:**
- Service → Metrics → CPU, RAM, Network usage

**Restart Service:**
- Service → Settings → Restart

---

## Troubleshooting

### Build Failed

**Check logs in Railway dashboard**

Common issues:
- Missing `package.json` → Ensure `api/package.json` exists
- TypeScript errors → Run `npm run build` locally first
- Node version → Railway uses Node 20 (specified in nixpacks.toml)

### MongoDB Connection Failed

**Check:**
- MongoDB service is running (Railway dashboard → MongoDB)
- `MONGODB_URI` env var is set correctly
- Network connectivity (Railway auto-handles this)

### API Returns 500 Errors

**Check logs for:**
- Missing env vars (`PROVIDER_URL`, contract addresses)
- Blockchain connection issues
- Smart contracts not deployed

**Fix:**
```bash
# In Railway dashboard
Variables → Check all required vars are set
Deployments → View Logs → Look for errors
```

### Contracts Not Responding

**Verify:**
- Contracts are deployed to Base Sepolia (check basescan.org)
- Contract addresses in Railway env vars are correct
- `PROVIDER_URL` is set to `https://sepolia.base.org`

---

## Cost Estimate

**Railway Free Tier:**
- $5/month credit
- Shared resources
- Auto-sleep after inactivity

**Expected Usage (MVP):**
- API: ~$3-4/month
- MongoDB: ~$1-2/month
- **Total: ~$5/month (free tier covers this!)**

**Upgrade if needed:**
- Hobby Plan: $5/month (no auto-sleep, better performance)
- Pro Plan: $20/month (dedicated resources)

---

## What Gets Deployed

Railway deploys the **API service only** (not contracts or plugin).

**File structure Railway sees:**
```
agent-marketplace/
├── api/                    ← Deployed to Railway
│   ├── src/
│   ├── package.json
│   └── ...
├── contracts/              ← Deploy separately (Remix/Foundry)
├── plugin/                 ← Use locally in OpenClaw
├── nixpacks.toml           ← Railway build config
└── railway.json            ← Railway deploy config
```

---

## Complete Deployment Checklist

- [ ] Railway project created from GitHub
- [ ] MongoDB service added
- [ ] Smart contracts deployed to Base Sepolia (Remix or Foundry)
- [ ] Railway env vars updated with contract addresses
- [ ] API deployed successfully (green status)
- [ ] Health check passes (`/health` returns 200)
- [ ] Test endpoints working (`/agents`, `/listings`)
- [ ] Plugin `.env` updated with Railway URL
- [ ] OpenClaw skill installed and configured
- [ ] End-to-end test: List item → Browse → Purchase

---

## Next Steps After Deploy

1. ✅ API running on Railway
2. ✅ MongoDB connected
3. ✅ Smart contracts on Base Sepolia
4. ⏳ Test OpenClaw plugin integration
5. ⏳ Run E2E demo (2 agents trading)
6. ⏳ Monitor and optimize

**You're live!** 🎉

Access your marketplace:
- API: `https://your-app.up.railway.app`
- Contracts: `https://sepolia.basescan.org/address/{contractAddress}`
- Logs: Railway dashboard → Service → Logs
