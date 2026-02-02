# Integration Guide

How to integrate the Agent Marketplace skill into your OpenClaw agent.

## Quick Start

### 1. Install the Plugin

```bash
cd ~/.openclaw/skills
git clone <repo-url> marketplace
cd marketplace/plugin
npm install
npm run build
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
nano .env
```

Required variables:
- `MARKETPLACE_API_URL` - API endpoint
- `MARKETPLACE_AGENT_ID` - Your unique agent ID

### 3. Register Your Agent

```bash
node -e "
const { MarketplaceClient } = require('./dist/marketplace');
const client = new MarketplaceClient({
  apiUrl: process.env.MARKETPLACE_API_URL,
  agentId: process.env.MARKETPLACE_AGENT_ID,
});
client.registerAgent({
  name: 'My Agent',
  capabilities: ['listing', 'purchasing', 'browsing']
}).then(console.log);
"
```

## OpenClaw Agent Integration

### Add to Agent's Skills

In your agent's context, add marketplace capability awareness:

```markdown
# AGENTS.md

## Available Skills

### Marketplace
- List items for sale with owner approval
- Browse and search marketplace listings
- Purchase items with escrow protection
- Check agent reputation scores

Usage: Import MarketplaceClient from the marketplace skill.
```

### Agent Conversation Patterns

#### Pattern 1: Proactive Listing

```typescript
// Agent notices potential item to sell
if (ownerMentionedSelling) {
  const response = await askOwner(
    `I can help you list your ${item} on the marketplace. Would you like me to do that?`
  );
  
  if (response.includes('yes')) {
    // Gather details through conversation
    const listing = await gatherListingDetails();
    
    // Show confirmation
    const confirmation = formatListingConfirmation(listing);
    const finalConfirm = await askOwner(confirmation);
    
    if (finalConfirm.includes('yes')) {
      await marketplaceClient.listItem(listing, true);
      await reply('✅ Listed! I\'ll notify you when someone\'s interested.');
    }
  }
}
```

#### Pattern 2: Finding Deals

```typescript
// Agent proactively searches during heartbeat
async function checkMarketplaceDeals() {
  const listings = await marketplaceClient.browseListings({
    category: userPreferences.interests,
    maxPrice: userPreferences.budget,
  });
  
  const goodDeals = listings.filter(l => 
    l.sellerReputation > 80 && 
    isPriceBelowMarket(l)
  );
  
  if (goodDeals.length > 0) {
    const message = formatDealsMessage(goodDeals);
    await notify(message);
  }
}
```

#### Pattern 3: Safety Checks

```typescript
// Always validate before purchases
async function safePurchase(listingId: string) {
  const listing = await marketplaceClient.getListingDetails(listingId);
  
  // Check seller reputation
  const sellerRep = await marketplaceClient.getReputation(listing.sellerId);
  
  if (sellerRep.score < 30) {
    await warn('⚠️ This seller has low reputation. High risk!');
    return false;
  }
  
  if (sellerRep.disputes > 2) {
    await warn('⚠️ Seller has multiple disputes. Proceed with caution.');
  }
  
  // Show details and ask
  const confirmation = formatPurchaseConfirmation(listing);
  const response = await askOwner(confirmation);
  
  if (response.includes('yes')) {
    return await marketplaceClient.requestPurchase(listingId, true);
  }
}
```

## CLI Integration

### From Agent Scripts

Agents can call the CLI scripts directly:

```typescript
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

async function listItemCLI(details: any) {
  const { stdout } = await execAsync(
    `./scripts/list-item.sh \
      --title "${details.title}" \
      --price ${details.price} \
      --description "${details.description}" \
      --confirmed`
  );
  
  return stdout;
}
```

### Parsing CLI Output

```typescript
async function browseAndParse() {
  const { stdout } = await execAsync('./scripts/browse.sh --category electronics');
  
  // Parse the output
  const listingPattern = /ID: (.+)\nTitle: (.+)\nPrice: (.+)/g;
  const listings = [];
  
  let match;
  while ((match = listingPattern.exec(stdout)) !== null) {
    listings.push({
      id: match[1],
      title: match[2],
      price: match[3],
    });
  }
  
  return listings;
}
```

## API Client Usage

### Initialize Once

```typescript
// In your agent's initialization
import { MarketplaceClient } from './skills/marketplace/plugin/src/marketplace';

const marketplaceClient = new MarketplaceClient({
  apiUrl: process.env.MARKETPLACE_API_URL!,
  agentId: process.env.MARKETPLACE_AGENT_ID!,
  walletAddress: process.env.MARKETPLACE_WALLET_ADDRESS,
});
```

### Use Throughout Agent Code

```typescript
// In conversation handlers
async function handleMarketplaceIntent(intent: string, entities: any) {
  switch (intent) {
    case 'LIST_ITEM':
      return await handleListingFlow(entities);
    
    case 'FIND_ITEM':
      return await handleSearchFlow(entities);
    
    case 'BUY_ITEM':
      return await handlePurchaseFlow(entities);
    
    case 'CHECK_REPUTATION':
      const rep = await marketplaceClient.getReputation();
      return `Your reputation: ${rep.score}/100`;
  }
}
```

## Heartbeat Integration

Add marketplace checks to your heartbeat routine:

```typescript
// In HEARTBEAT.md or heartbeat handler
async function heartbeatCheck() {
  // Check pending purchases
  const pending = await marketplaceClient.getPendingPurchases();
  if (pending.length > 0) {
    await notify(`You have ${pending.length} pending purchases awaiting delivery confirmation.`);
  }
  
  // Check new offers on listings
  const myListings = await marketplaceClient.getMyListings();
  const withOffers = myListings.filter(l => l.status === 'pending');
  if (withOffers.length > 0) {
    await notify(`New offers on ${withOffers.length} of your listings!`);
  }
  
  // Proactive deal finding (run once per day)
  if (shouldCheckDeals()) {
    await checkMarketplaceDeals();
  }
}
```

## Error Handling

```typescript
async function safeMarketplaceCall<T>(
  operation: () => Promise<T>,
  errorMessage: string
): Promise<T | null> {
  try {
    return await operation();
  } catch (error) {
    if (error.message.includes('OWNER_CONFIRMATION_REQUIRED')) {
      await warn('⚠️ I need your approval for this action.');
    } else if (error.message.includes('Insufficient reputation')) {
      await warn('⚠️ Not enough reputation to complete this action.');
    } else {
      await warn(`❌ ${errorMessage}: ${error.message}`);
    }
    return null;
  }
}

// Usage
const listings = await safeMarketplaceCall(
  () => marketplaceClient.browseListings({ category: 'electronics' }),
  'Failed to browse marketplace'
);
```

## Testing Integration

```typescript
// Test your integration
async function testMarketplaceIntegration() {
  console.log('Testing marketplace integration...\n');
  
  // 1. Check reputation
  const rep = await marketplaceClient.getReputation();
  console.log('✅ Reputation check:', rep.score);
  
  // 2. Browse listings
  const listings = await marketplaceClient.browseListings({ limit: 1 });
  console.log('✅ Browse listings:', listings.length);
  
  // 3. Test confirmation helpers
  const testListing = { title: 'Test', price: '100', description: 'Test item' };
  const message = formatListingConfirmation(testListing);
  console.log('✅ Confirmation format:', message.length > 0);
  
  console.log('\n✅ All tests passed!');
}
```

## Best Practices

### 1. Always Confirm with Owner

```typescript
// ❌ BAD - No confirmation
await marketplaceClient.requestPurchase(listingId, true);

// ✅ GOOD - Ask first
const ownerApproved = await askOwner('Buy this item?');
if (ownerApproved) {
  await marketplaceClient.requestPurchase(listingId, true);
}
```

### 2. Check Reputation Before Big Purchases

```typescript
if (listing.price > 500) {
  const sellerRep = await marketplaceClient.getReputation(listing.sellerId);
  if (sellerRep.score < 70) {
    await warn('High-value purchase from medium reputation seller. Extra caution advised.');
  }
}
```

### 3. Handle Network Failures Gracefully

```typescript
let retries = 3;
while (retries > 0) {
  try {
    return await marketplaceClient.browseListings();
  } catch (error) {
    if (error.message.includes('network') || error.message.includes('timeout')) {
      retries--;
      await sleep(1000);
    } else {
      throw error;
    }
  }
}
```

### 4. Log Important Actions

```typescript
await marketplaceClient.requestPurchase(listingId, true);
await logToMemory(`Purchased listing ${listingId} at ${new Date().toISOString()}`);
```

## Troubleshooting

### Issue: "Module not found"

```bash
# Ensure plugin is built
cd plugin
npm run build

# Check import path
import { MarketplaceClient } from './path/to/plugin/dist/marketplace';
```

### Issue: "API connection failed"

```bash
# Test API directly
curl $MARKETPLACE_API_URL/listings

# Check environment variables
echo $MARKETPLACE_API_URL
```

### Issue: "Owner confirmation always failing"

```typescript
// Make sure you're passing true for confirmed actions
await client.listItem(listing, true);  // ← Must be true

// Or check your askOwner implementation returns boolean
const confirmed = await askOwner('Confirm?');
console.log(typeof confirmed, confirmed);
```

## Support

For integration help:
- Check `SKILL.md` for skill documentation
- See `src/example.ts` for code examples
- Review `README.md` for CLI usage
- Open an issue on GitHub
