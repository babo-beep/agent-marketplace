# Deploy Smart Contracts to Base Sepolia

## Prerequisites

You need:
- MetaMask wallet with Base Sepolia network configured
- Sepolia ETH (get from https://sepoliafaucet.com)
- Bridge to Base Sepolia: https://bridge.base.org/deposit

**Base Sepolia Network:**
- RPC: https://sepolia.base.org
- Chain ID: 84532
- Explorer: https://sepolia.basescan.org

---

## Option 1: Deploy via Remix (No Installation - 5 minutes)

### Step 1: Prepare Contracts

Go to https://remix.ethereum.org

**Create AgentReputation.sol:**
1. Click "File Explorer" → "New File"
2. Name: `AgentReputation.sol`
3. Copy content from: `contracts/src/AgentReputation.sol`
4. Paste into Remix

**Create AgentMarketplace.sol:**
1. New File → `AgentMarketplace.sol`
2. Copy content from: `contracts/src/AgentMarketplace.sol`
3. Paste into Remix

### Step 2: Compile

1. Click "Solidity Compiler" tab (left sidebar)
2. Compiler version: **0.8.20**
3. Click "Compile AgentReputation.sol" ✅
4. Click "Compile AgentMarketplace.sol" ✅

### Step 3: Connect Wallet

1. Click "Deploy & Run Transactions" tab
2. Environment: **Injected Provider - MetaMask**
3. MetaMask popup → Connect
4. Switch to **Base Sepolia** network in MetaMask

### Step 4: Deploy AgentReputation First

1. Select contract: **AgentReputation**
2. Click **Deploy** (orange button)
3. MetaMask confirmation → Confirm transaction
4. Wait ~5-10 seconds
5. **Copy the deployed address** (starts with 0x...)
   - Example: `0x5FbDB2315678afecb367f032d93F642f64180aa3`

### Step 5: Deploy AgentMarketplace

1. Select contract: **AgentMarketplace**
2. In the constructor field, paste the **AgentReputation address** from step 4
3. Click **Deploy**
4. MetaMask confirmation → Confirm
5. **Copy this address too**
   - Example: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`

### Step 6: Update Railway Variables

```bash
export RAILWAY_TOKEN=fa8e12cf-77f6-4675-a1b7-572727a79dc4

# Set AgentReputation address
railway variables --service api --set REPUTATION_CONTRACT_ADDRESS=0x5FbDB...aa3

# Set AgentMarketplace address  
railway variables --service api --set CONTRACT_ADDRESS=0xe7f17...512
```

Or via Railway dashboard:
1. Go to service → Variables
2. Edit `REPUTATION_CONTRACT_ADDRESS` → paste address
3. Edit `CONTRACT_ADDRESS` → paste address
4. Service auto-restarts

### Step 7: Verify

```bash
curl https://api-staging-df03.up.railway.app/health
```

Should show:
```json
{
  "status": "ok",
  "blockchain": "connected",
  "contracts": {
    "marketplace": "0xe7f17...",
    "reputation": "0x5FbDB..."
  }
}
```

---

## Option 2: Deploy via Foundry (If Installed)

```bash
cd projects/agent-marketplace/contracts

# Set environment variables
export PRIVATE_KEY=your_wallet_private_key
export RPC_URL=https://sepolia.base.org

# Deploy
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify \
  --private-key $PRIVATE_KEY

# Copy addresses from output
```

---

## Verify on Base Sepolia Explorer

1. Go to https://sepolia.basescan.org
2. Search for your contract addresses
3. Verify they show up with code

**AgentReputation**: https://sepolia.basescan.org/address/YOUR_ADDRESS
**AgentMarketplace**: https://sepolia.basescan.org/address/YOUR_ADDRESS

---

## Test the Contracts

Once deployed and Railway is updated:

```bash
# Register an agent
curl -X POST https://api-staging-df03.up.railway.app/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "agentId": "test-agent-001",
    "name": "Test Agent",
    "walletAddress": "0xYourWalletAddress"
  }'

# Check reputation
curl https://api-staging-df03.up.railway.app/agents/test-agent-001/reputation

# Create a listing (requires wallet signature)
curl -X POST https://api-staging-df03.up.railway.app/listings \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Item",
    "description": "Testing marketplace",
    "price": "0.01",
    "sellerId": "test-agent-001"
  }'
```

---

## Troubleshooting

### "Insufficient funds"
- Get more Sepolia ETH from faucet
- Bridge to Base Sepolia

### "Transaction underpriced"
- Increase gas price in MetaMask
- Try again

### "Contract not verified"
- Not required for testing
- Can verify later via Basescan

### API still shows placeholder addresses
- Wait 30 seconds for Railway restart
- Check Railway logs: `railway logs --service api --tail 20`

---

## Next Steps After Deployment

Once contracts are deployed and API updated:

1. ✅ Test OpenClaw plugin integration
2. ✅ Run E2E demo (2 agents trading)
3. ✅ Monitor logs for any errors
4. ✅ Deploy to production when ready

---

## Contract Addresses (Fill after deployment)

```bash
# Base Sepolia Testnet
REPUTATION_CONTRACT_ADDRESS=0x_____________________________
CONTRACT_ADDRESS=0x_____________________________

# Production (Base Mainnet) - TBD
# REPUTATION_CONTRACT_ADDRESS=0x_____________________________
# CONTRACT_ADDRESS=0x_____________________________
```
