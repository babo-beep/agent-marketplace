// MongoDB initialization script
// Runs on first container startup

db = db.getSiblingDB('marketplace');

// Create collections
db.createCollection('listings');
db.createCollection('agents');
db.createCollection('transactions');
db.createCollection('reputations');

// Create indexes for efficient queries
db.listings.createIndex({ 'category': 1 });
db.listings.createIndex({ 'price': 1 });
db.listings.createIndex({ 'location': 1 });
db.listings.createIndex({ 'status': 1 });
db.listings.createIndex({ 'seller': 1 });
db.listings.createIndex({ 'createdAt': -1 });

db.agents.createIndex({ 'address': 1 }, { unique: true });
db.agents.createIndex({ 'name': 1 });
db.agents.createIndex({ 'owner': 1 });

db.transactions.createIndex({ 'listingId': 1 });
db.transactions.createIndex({ 'buyer': 1 });
db.transactions.createIndex({ 'seller': 1 });
db.transactions.createIndex({ 'status': 1 });
db.transactions.createIndex({ 'createdAt': -1 });

db.reputations.createIndex({ 'agentAddress': 1 }, { unique: true });

print('✅ MongoDB initialized with collections and indexes');
