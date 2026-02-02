/**
 * Example usage of the Marketplace Client
 * 
 * This file demonstrates how an OpenClaw agent would use the marketplace skill
 */

import MarketplaceClient, {
  formatListingConfirmation,
  formatPurchaseConfirmation,
  formatDeliveryConfirmation,
} from './marketplace';

// Initialize the client
const client = new MarketplaceClient({
  apiUrl: process.env.MARKETPLACE_API_URL || 'http://localhost:3000',
  agentId: process.env.MARKETPLACE_AGENT_ID || 'agent-example',
  walletAddress: process.env.MARKETPLACE_WALLET_ADDRESS,
});

/**
 * Example 1: Agent helps owner list an item
 */
async function exampleListItem() {
  console.log('=== Example 1: Listing an Item ===\n');
  
  // Agent conversation with owner (simulated)
  console.log('Owner: "I want to sell my old laptop"');
  console.log('Agent: "Great! Let me help you list it..."\n');
  
  // Agent gathers information (through conversation)
  const itemDetails = {
    title: 'MacBook Pro 2019',
    description: '15-inch, 16GB RAM, 512GB SSD, excellent condition',
    price: '800',
    condition: 'excellent',
    category: 'electronics',
  };
  
  // Agent asks for confirmation
  const confirmationMessage = formatListingConfirmation(itemDetails);
  console.log('Agent asks owner:\n', confirmationMessage);
  
  // Simulate owner response
  const ownerApproved = true; // In real usage, this comes from owner chat
  
  if (ownerApproved) {
    try {
      const listing = await client.listItem(itemDetails, true);
      console.log('\n✅ Listing created:', listing);
    } catch (error) {
      console.error('❌ Failed to list item:', error);
    }
  }
}

/**
 * Example 2: Agent browses and finds deals
 */
async function exampleBrowseAndFind() {
  console.log('\n=== Example 2: Browsing Listings ===\n');
  
  console.log('Agent: "Let me check the marketplace for laptops under $1000..."\n');
  
  try {
    const listings = await client.browseListings({
      category: 'electronics',
      maxPrice: 1000,
      search: 'laptop',
      limit: 5,
    });
    
    console.log(`Found ${listings.length} listings:`);
    listings.forEach((listing, index) => {
      console.log(`\n${index + 1}. ${listing.title}`);
      console.log(`   Price: ${listing.price} USDC`);
      console.log(`   Condition: ${listing.condition}`);
      console.log(`   Seller Reputation: ${listing.sellerReputation || 'N/A'}/100`);
    });
    
    // Agent might proactively alert owner about good deals
    if (listings.length > 0) {
      const bestDeal = listings[0];
      console.log('\nAgent: "I found a great deal! Would you like me to purchase it?"');
    }
  } catch (error) {
    console.error('❌ Failed to browse:', error);
  }
}

/**
 * Example 3: Agent purchases with owner approval
 */
async function examplePurchaseItem(listingId: string) {
  console.log('\n=== Example 3: Purchasing an Item ===\n');
  
  try {
    // First, get listing details
    const listing = await client.getListingDetails(listingId);
    
    // Agent presents to owner
    const confirmationMessage = formatPurchaseConfirmation(listing);
    console.log('Agent asks owner:\n', confirmationMessage);
    
    // Simulate owner response
    const ownerApproved = true;
    
    if (ownerApproved) {
      const purchase = await client.requestPurchase(listingId, true);
      console.log('\n✅ Purchase initiated:', purchase);
      console.log('Agent: "Funds are in escrow. I\'ll notify you when it arrives!"');
    } else {
      console.log('Agent: "No problem, I\'ll keep looking for other options."');
    }
  } catch (error) {
    console.error('❌ Failed to purchase:', error);
  }
}

/**
 * Example 4: Agent checks reputation
 */
async function exampleCheckReputation() {
  console.log('\n=== Example 4: Checking Reputation ===\n');
  
  try {
    const reputation = await client.getReputation();
    
    console.log('Your Marketplace Reputation:');
    console.log(`Score: ${reputation.score}/100`);
    console.log(`Total Transactions: ${reputation.totalTransactions}`);
    console.log(`Successful: ${reputation.successfulTransactions}`);
    console.log(`Disputes: ${reputation.disputes}`);
    
    if (reputation.score >= 80) {
      console.log('✅ Excellent reputation!');
    } else if (reputation.score >= 50) {
      console.log('👍 Good reputation');
    } else {
      console.log('⚠️  Reputation needs improvement');
    }
  } catch (error) {
    console.error('❌ Failed to get reputation:', error);
  }
}

/**
 * Example 5: Agent confirms delivery
 */
async function exampleConfirmDelivery(listingId: string) {
  console.log('\n=== Example 5: Confirming Delivery ===\n');
  
  console.log('Agent: "Your package has arrived! Have you inspected it?"\n');
  
  const confirmationMessage = formatDeliveryConfirmation(
    listingId,
    'MacBook Pro 2019'
  );
  console.log(confirmationMessage);
  
  // Simulate owner confirming receipt
  const ownerConfirmed = true;
  
  if (ownerConfirmed) {
    try {
      const result = await client.confirmDelivery(listingId, true);
      console.log('\n✅ Delivery confirmed:', result);
      console.log('Agent: "Funds released to seller. Both agents gained +10 reputation!"');
    } catch (error) {
      console.error('❌ Failed to confirm delivery:', error);
    }
  }
}

/**
 * Example 6: Full workflow - List and Buy
 */
async function exampleFullWorkflow() {
  console.log('\n=== Example 6: Complete Workflow ===\n');
  
  try {
    // 1. Check initial reputation
    console.log('1. Checking initial reputation...');
    await exampleCheckReputation();
    
    // 2. List an item
    console.log('\n2. Listing an item for sale...');
    await exampleListItem();
    
    // 3. Browse marketplace
    console.log('\n3. Browsing marketplace...');
    await exampleBrowseAndFind();
    
    // 4. Get pending purchases
    console.log('\n4. Checking pending purchases...');
    const pending = await client.getPendingPurchases();
    console.log(`Found ${pending.length} pending purchases`);
    
    // 5. Get agent's listings
    console.log('\n5. Checking my listings...');
    const myListings = await client.getMyListings();
    console.log(`You have ${myListings.length} active listings`);
    
    console.log('\n✅ Workflow complete!');
  } catch (error) {
    console.error('❌ Workflow failed:', error);
  }
}

// Run examples if this file is executed directly
if (require.main === module) {
  console.log('🤖 Agent Marketplace Plugin - Example Usage\n');
  console.log('============================================\n');
  
  // Run a simple workflow
  exampleFullWorkflow()
    .then(() => {
      console.log('\n✅ All examples completed!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Examples failed:', error);
      process.exit(1);
    });
}

// Export for use in other modules
export {
  exampleListItem,
  exampleBrowseAndFind,
  examplePurchaseItem,
  exampleCheckReputation,
  exampleConfirmDelivery,
  exampleFullWorkflow,
};
