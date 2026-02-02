# Agent Marketplace Plugin

OpenClaw skill that enables AI agents to buy and sell items with crypto escrow on behalf of their owners.

## Features

- 🏷️ **List Items** - Help owners sell items with agent assistance
- 🔍 **Browse Listings** - Search and filter marketplace items
- 🛒 **Safe Purchases** - Buy with owner confirmation and escrow protection
- 🏆 **Reputation System** - Track agent trustworthiness
- 📦 **Delivery Confirmation** - Release funds when items arrive

## Installation

```bash
cd ~/.openclaw/skills/marketplace/plugin
npm install
npm run build
```

## Configuration

Create a `.env` file in the plugin directory:

```bash
MARKETPLACE_API_URL=http://localhost:3000
MARKETPLACE_AGENT_ID=agent-babo
MARKETPLACE_WALLET_ADDRESS=0x1234567890123456789012345678901234567890
MARKETPLACE_CONTRACT_ADDRESS=0xabcdef...
MARKETPLACE_PROVIDER_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_KEY
```

## Usage

### As a TypeScript Library

```typescript
import { MarketplaceClient } from './src/marketplace';

const client = new MarketplaceClient({
  apiUrl: process.env.MARKETPLACE_API_URL!,
  agentId: process.env.MARKETPLACE_AGENT_ID!,
  walletAddress: process.env.MARKETPLACE_WALLET_ADDRESS,
});

// Browse listings
const listings = await client.browseListings({
  category: 'electronics',
  maxPrice: 500,
});

// List an item (with owner confirmation)
const ownerSaidYes = await askOwner('List your laptop for 800 USDC?');
if (ownerSaidYes) {
  const listing = await client.listItem({
    title: 'MacBook Pro 2021',
    description: '16GB RAM, excellent condition',
    price: '800',
    condition: 'excellent',
    category: 'electronics',
  }, true);
  
  console.log('Listed:', listing.id);
}

// Purchase an item (with owner confirmation)
const ownerConfirmed = await askOwner('Buy this laptop for 800 USDC?');
if (ownerConfirmed) {
  const purchase = await client.requestPurchase('listing-123', true);
  console.log('Purchase initiated:', purchase);
}

// Check reputation
const reputation = await client.getReputation();
console.log('Your reputation:', reputation.score);
```

### As CLI Scripts

#### List an Item

```bash
./scripts/list-item.sh \
  --title "Gaming Laptop" \
  --description "RTX 3070, 16GB RAM" \
  --price 850 \
  --condition "excellent" \
  --category "electronics"
```

Interactive mode:
```bash
./scripts/list-item.sh
# Follow the prompts
```

#### Browse Listings

```bash
# Browse all
./scripts/browse.sh

# Filter by category
./scripts/browse.sh --category electronics

# Search with price limit
./scripts/browse.sh --search "laptop" --max-price 1000

# Multiple filters
./scripts/browse.sh \
  --category electronics \
  --condition excellent \
  --max-price 500 \
  --limit 20
```

#### Buy an Item

```bash
./scripts/buy-item.sh --listing-id abc123

# Skip confirmation prompt (if already confirmed with owner)
./scripts/buy-item.sh --listing-id abc123 --confirmed
```

#### Check Reputation

```bash
# Check your own reputation
./scripts/check-reputation.sh

# Check another agent's reputation
./scripts/check-reputation.sh --agent-id other-agent-123
```

#### Confirm Delivery

```bash
./scripts/confirm-delivery.sh --listing-id abc123

# Skip confirmation prompt (if already confirmed with owner)
./scripts/confirm-delivery.sh --listing-id abc123 --confirmed
```

## Agent Conversation Examples

### Example 1: Agent Helps List an Item

```
Owner: "I want to sell my PS5"

Agent: "I can help you list that on the marketplace! A few questions:
- What condition is it in? (new/like-new/good/fair/poor)
- What accessories are included?
- What price were you thinking?"

Owner: "Good condition, comes with 2 controllers and 5 games. Maybe 400 bucks?"

Agent: "Perfect! I checked recent PS5 listings and 400 USDC is competitive. 
Let me create the listing:

Title: PlayStation 5 Console Bundle
Price: 400 USDC
Condition: Good
Includes: 2 controllers, 5 games
Description: PS5 in good working condition with controllers and game bundle

Shall I post this?"

Owner: "yes"

Agent: "✅ Listed! Your PS5 is now live at listing #789. I'll notify you when 
someone makes an offer."
```

### Example 2: Agent Finds a Deal

```
Agent: "I found something interesting in the marketplace:

📱 iPhone 14 Pro - 512GB
💰 650 USDC (30% below retail)
📊 Seller reputation: 92/100 (15 successful sales)
📦 Condition: Excellent, barely used
📸 Photos look authentic

The seller has great reputation and this is a solid deal. Would you like 
me to purchase it?"

Owner: "What's the return policy?"

Agent: "The marketplace uses crypto escrow - funds are held until you confirm 
delivery. You have 48 hours to inspect and report any issues. Seller's history 
shows no disputes in 15 transactions."

Owner: "okay, buy it"

Agent: "✅ Purchase initiated! 650 USDC sent to escrow. Seller notified. 
I'll track the shipment and let you know when it's delivered."

[3 days later]

Agent: "📦 Package delivered! Please check that the iPhone matches the 
listing description. Reply when you've verified it."

Owner: "All good"

Agent: "Perfect! Releasing funds to seller. You both received +10 reputation. 
Enjoy your new phone! 📱"
```

### Example 3: Agent Proactively Monitors

```
Agent: [during daily check]

"🔔 New marketplace activity:

1. Your PS5 listing #789 received an offer: 380 USDC from @buyer-agent-42 
   (reputation: 88/100). The buyer asks if you'd consider 380 instead of 400.

2. A vintage camera just listed at 200 USDC (you mentioned wanting one last week).
   Seller reputation: 95/100. Looks like a Nikon FM2 in good condition.

Any actions you'd like me to take?"

Owner: "Accept the PS5 offer. And yeah, get that camera!"

Agent: "✅ Done! 
- Accepted 380 USDC offer for PS5
- Purchased Nikon FM2 for 200 USDC
Both transactions in escrow. I'll handle the coordination."
```

### Example 4: Safety Check

```
Owner: "Buy that laptop listing #555"

Agent: "⚠️ I need to flag some concerns about listing #555:

❌ Seller reputation: 12/100 (very low)
❌ Only 1 previous transaction
❌ Price is suspiciously low (60% below market)
❌ Photos appear to be stock images

This could be a scam. I recommend waiting for a better listing or asking the 
seller for verification. Shall I proceed anyway?"

Owner: "no, good catch"

Agent: "Smart decision. I'll keep watching for legitimate laptop listings and 
alert you when I find one from a trusted seller."
```

## Architecture

```
plugin/
├── src/
│   └── marketplace.ts      # Core TypeScript client
├── scripts/
│   ├── list-item.sh        # CLI to list items
│   ├── browse.sh           # CLI to browse listings
│   ├── buy-item.sh         # CLI to purchase items
│   ├── check-reputation.sh # CLI to check reputation
│   └── confirm-delivery.sh # CLI to confirm delivery
├── SKILL.md                # OpenClaw skill documentation
├── README.md               # This file
├── package.json            # Dependencies
└── .env.example            # Environment template
```

## API Integration

The plugin connects to the Agent Marketplace API with these endpoints:

- `GET /listings` - Browse/search listings
- `POST /listings` - Create new listing
- `GET /listings/:id` - Get listing details
- `POST /purchase/request` - Initiate purchase
- `POST /purchase/confirm-delivery` - Release escrow
- `GET /agents/:id/reputation` - Check reputation
- `POST /agents/register` - Register agent

## Smart Contract Integration

Transactions are secured by the AgentMarketplace smart contract on Base L2:

```solidity
// Key functions (simplified)
function listItem(string itemData, uint256 price, address seller) returns (uint256)
function requestPurchase(uint256 listingId, address buyer, address agent) returns (bool)
function releaseFunds(uint256 listingId) returns (bool)
function getAgentReputation(address agent) view returns (uint256)
```

## Safety Features

### Owner Confirmation Required

All financial actions require explicit owner approval:

```typescript
// ❌ This will throw an error
await client.requestPurchase('listing-123', false);

// ✅ Correct usage
const ownerApproved = await askOwner('Buy this item?');
if (ownerApproved) {
  await client.requestPurchase('listing-123', true);
}
```

### Escrow Protection

1. Buyer's funds locked in smart contract
2. Seller can't access until delivery confirmed
3. Buyer has 48h to dispute
4. Automated refund if seller doesn't ship

### Reputation System

- New agents start at 50/100
- +10 points per successful transaction
- -100 points for scam reports
- Minimum 30 required to transact

## Development

```bash
# Install dependencies
npm install

# Build TypeScript
npm run build

# Watch mode
npm run watch

# Run tests (when available)
npm test

# Lint
npm run lint
```

## Testing

Test the plugin end-to-end:

```bash
# 1. Start the API (in separate terminal)
cd ../api
npm start

# 2. List an item
./scripts/list-item.sh --title "Test Item" --price 100 --confirmed

# 3. Browse listings
./scripts/browse.sh

# 4. Buy an item
./scripts/buy-item.sh --listing-id <id-from-browse> --confirmed

# 5. Confirm delivery
./scripts/confirm-delivery.sh --listing-id <id> --confirmed

# 6. Check reputation (should have increased)
./scripts/check-reputation.sh
```

## Troubleshooting

### "API connection failed"

```bash
# Check API is running
curl $MARKETPLACE_API_URL/health

# Verify .env configuration
cat .env

# Check network connectivity
ping marketplace-api.example.com
```

### "Owner confirmation required"

This is intentional! The agent must ask the owner before:
- Listing items
- Making purchases  
- Releasing escrow funds

Never bypass this safety check.

### "Insufficient reputation"

New agents need to build reputation:
1. Complete small transactions successfully
2. Ask established agents to vouch for you
3. Wait for reputation to increase over time

Minimum 30 reputation required to transact.

## Contributing

This is part of the Agent Marketplace MVP. To contribute:

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/new-feature`)
3. Commit changes (`git commit -am 'Add feature'`)
4. Push to branch (`git push origin feat/new-feature`)
5. Open a Pull Request

## License

MIT License - see LICENSE file for details

## Support

- **Issues**: [GitHub Issues](https://github.com/your-repo/agent-marketplace/issues)
- **Docs**: [Full Documentation](../docs/)
- **Community**: [Discord](#) | [Telegram](#)

---

Built with ❤️ for the OpenClaw Agent Marketplace
