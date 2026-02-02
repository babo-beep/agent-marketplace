#!/bin/bash

# Seed database with sample listings and agents for testing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Seeding database with sample data...${NC}"

# Sample agent addresses from Hardhat's default accounts
AGENT_ALICE="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
AGENT_BOB="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
AGENT_CHARLIE="0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"

# Seed agents
echo "Creating sample agents..."
docker exec marketplace-mongodb mongosh marketplace --eval "
db.agents.deleteMany({});
db.agents.insertMany([
    {
        name: 'AgentAlice',
        address: '$AGENT_ALICE',
        owner: 'alice@example.com',
        reputation: 100,
        transactionCount: 0,
        successfulSales: 0,
        successfulPurchases: 0,
        totalVolume: 0,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        name: 'AgentBob',
        address: '$AGENT_BOB',
        owner: 'bob@example.com',
        reputation: 100,
        transactionCount: 0,
        successfulSales: 0,
        successfulPurchases: 0,
        totalVolume: 0,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        name: 'AgentCharlie',
        address: '$AGENT_CHARLIE',
        owner: 'charlie@example.com',
        reputation: 95,
        transactionCount: 0,
        successfulSales: 0,
        successfulPurchases: 0,
        totalVolume: 0,
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);
print('✅ Agents created');
" --quiet

# Seed sample listings
echo "Creating sample listings..."
docker exec marketplace-mongodb mongosh marketplace --eval "
db.listings.deleteMany({});
db.listings.insertMany([
    {
        title: 'iPhone 14 Pro - Excellent Condition',
        description: 'Barely used iPhone 14 Pro, 256GB, Space Black. Includes original box and accessories.',
        category: 'Electronics',
        price: 0.5,  // 0.5 ETH
        currency: 'ETH',
        location: 'Amsterdam, NL',
        seller: '$AGENT_ALICE',
        sellerName: 'AgentAlice',
        status: 'active',
        photos: ['https://via.placeholder.com/400x300?text=iPhone+14+Pro'],
        condition: 'excellent',
        blockchain: {
            listingId: null,
            contractAddress: null,
            transactionHash: null
        },
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        title: 'Mountain Bike - Trek X-Caliber',
        description: 'Trek X-Caliber 8, size M, 29er wheels. Great for trails, minimal wear.',
        category: 'Sports',
        price: 1.2,
        currency: 'ETH',
        location: 'Berlin, DE',
        seller: '$AGENT_ALICE',
        sellerName: 'AgentAlice',
        status: 'active',
        photos: ['https://via.placeholder.com/400x300?text=Mountain+Bike'],
        condition: 'good',
        blockchain: {
            listingId: null,
            contractAddress: null,
            transactionHash: null
        },
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        title: 'Designer Leather Jacket',
        description: 'Genuine leather jacket from Schott NYC, size L. Vintage style, well maintained.',
        category: 'Fashion',
        price: 0.3,
        currency: 'ETH',
        location: 'Paris, FR',
        seller: '$AGENT_CHARLIE',
        sellerName: 'AgentCharlie',
        status: 'active',
        photos: ['https://via.placeholder.com/400x300?text=Leather+Jacket'],
        condition: 'good',
        blockchain: {
            listingId: null,
            contractAddress: null,
            transactionHash: null
        },
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        title: 'Sony PlayStation 5 Bundle',
        description: 'PS5 disc edition with 2 controllers and 3 games: Spider-Man 2, Horizon, Elden Ring.',
        category: 'Electronics',
        price: 0.8,
        currency: 'ETH',
        location: 'London, UK',
        seller: '$AGENT_CHARLIE',
        sellerName: 'AgentCharlie',
        status: 'active',
        photos: ['https://via.placeholder.com/400x300?text=PS5+Bundle'],
        condition: 'excellent',
        blockchain: {
            listingId: null,
            contractAddress: null,
            transactionHash: null
        },
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        title: 'Vintage Camera - Canon AE-1',
        description: 'Classic Canon AE-1 film camera with 50mm f/1.8 lens. Fully functional, tested.',
        category: 'Electronics',
        price: 0.15,
        currency: 'ETH',
        location: 'Amsterdam, NL',
        seller: '$AGENT_ALICE',
        sellerName: 'AgentAlice',
        status: 'active',
        photos: ['https://via.placeholder.com/400x300?text=Canon+AE-1'],
        condition: 'good',
        blockchain: {
            listingId: null,
            contractAddress: null,
            transactionHash: null
        },
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);
print('✅ Listings created');
" --quiet

# Initialize reputation collection
echo "Initializing reputation data..."
docker exec marketplace-mongodb mongosh marketplace --eval "
db.reputations.deleteMany({});
db.reputations.insertMany([
    {
        agentAddress: '$AGENT_ALICE',
        agentName: 'AgentAlice',
        score: 100,
        totalTransactions: 0,
        successfulTransactions: 0,
        failedTransactions: 0,
        scamReports: 0,
        positiveReviews: 0,
        negativeReviews: 0,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        agentAddress: '$AGENT_BOB',
        agentName: 'AgentBob',
        score: 100,
        totalTransactions: 0,
        successfulTransactions: 0,
        failedTransactions: 0,
        scamReports: 0,
        positiveReviews: 0,
        negativeReviews: 0,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        agentAddress: '$AGENT_CHARLIE',
        agentName: 'AgentCharlie',
        score: 95,
        totalTransactions: 0,
        successfulTransactions: 0,
        failedTransactions: 0,
        scamReports: 0,
        positiveReviews: 0,
        negativeReviews: 0,
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);
print('✅ Reputation data initialized');
" --quiet

echo -e "${GREEN}✅ Database seeded successfully!${NC}"
echo ""
echo "Sample data created:"
echo "  • 3 agents (Alice, Bob, Charlie)"
echo "  • 5 listings (various categories)"
echo "  • Reputation entries for all agents"
echo ""
echo "You can now browse listings at http://localhost:3000/listings"
