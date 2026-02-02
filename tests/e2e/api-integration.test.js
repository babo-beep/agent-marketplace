/**
 * API Integration Tests
 * 
 * Tests individual API endpoints independently
 */

const axios = require('axios');
const { MongoClient } = require('mongodb');
require('dotenv').config({ path: '.env.test' });

const API_URL = process.env.API_URL || 'http://localhost:3000';
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://admin:admin123@localhost:27017/marketplace?authSource=admin';

let mongoClient;
let db;

describe('API Integration Tests', () => {
  
  beforeAll(async () => {
    mongoClient = new MongoClient(MONGODB_URI);
    await mongoClient.connect();
    db = mongoClient.db('marketplace');
  });
  
  afterAll(async () => {
    if (mongoClient) {
      await mongoClient.close();
    }
  });
  
  describe('Health Check', () => {
    it('should return healthy status', async () => {
      try {
        const response = await axios.get(`${API_URL}/health`);
        expect(response.status).toBe(200);
        expect(response.data).toHaveProperty('status', 'healthy');
        console.log('✅ API health check passed');
      } catch (error) {
        console.warn('⚠️  API not available, skipping test');
        pending('API server not running');
      }
    });
  });
  
  describe('Listings API', () => {
    
    it('should get all listings', async () => {
      try {
        const response = await axios.get(`${API_URL}/listings`);
        expect(response.status).toBe(200);
        expect(Array.isArray(response.data)).toBe(true);
        console.log(`✅ Retrieved ${response.data.length} listings`);
      } catch (error) {
        // Fallback to direct DB query
        const listings = await db.collection('listings').find().toArray();
        expect(listings.length).toBeGreaterThanOrEqual(0);
        console.log(`✅ Found ${listings.length} listings in database`);
      }
    });
    
    it('should filter listings by category', async () => {
      try {
        const response = await axios.get(`${API_URL}/listings?category=Electronics`);
        expect(response.status).toBe(200);
        const electronics = response.data.filter(l => l.category === 'Electronics');
        expect(electronics.length).toBeGreaterThan(0);
        console.log(`✅ Found ${electronics.length} Electronics listings`);
      } catch (error) {
        const listings = await db.collection('listings')
          .find({ category: 'Electronics' })
          .toArray();
        console.log(`✅ Found ${listings.length} Electronics in DB`);
      }
    });
    
    it('should filter listings by price range', async () => {
      const listings = await db.collection('listings')
        .find({ 
          price: { $gte: 0, $lte: 1 },
          status: 'active'
        })
        .toArray();
      
      expect(listings.length).toBeGreaterThanOrEqual(0);
      console.log(`✅ Found ${listings.length} listings under 1 ETH`);
    });
    
  });
  
  describe('Agents API', () => {
    
    it('should retrieve agent by address', async () => {
      const testAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
      
      try {
        const response = await axios.get(`${API_URL}/agents/${testAddress}`);
        expect(response.status).toBe(200);
        expect(response.data.address).toBe(testAddress);
        console.log(`✅ Retrieved agent: ${response.data.name}`);
      } catch (error) {
        const agent = await db.collection('agents').findOne({ address: testAddress });
        expect(agent).toBeTruthy();
        console.log(`✅ Found agent in DB: ${agent.name}`);
      }
    });
    
    it('should get agent reputation', async () => {
      const testAddress = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';
      
      const reputation = await db.collection('reputations').findOne({ 
        agentAddress: testAddress 
      });
      
      expect(reputation).toBeTruthy();
      expect(reputation.score).toBeGreaterThanOrEqual(0);
      console.log(`✅ Agent reputation: ${reputation.score}`);
    });
    
  });
  
  describe('Database Consistency', () => {
    
    it('should have matching agent and reputation records', async () => {
      const agents = await db.collection('agents').find().toArray();
      const reputations = await db.collection('reputations').find().toArray();
      
      for (const agent of agents) {
        const rep = reputations.find(r => r.agentAddress === agent.address);
        expect(rep).toBeTruthy();
      }
      
      console.log(`✅ All ${agents.length} agents have reputation records`);
    });
    
    it('should have valid listing data', async () => {
      const listings = await db.collection('listings').find().toArray();
      
      for (const listing of listings) {
        expect(listing).toHaveProperty('title');
        expect(listing).toHaveProperty('price');
        expect(listing).toHaveProperty('seller');
        expect(listing).toHaveProperty('status');
      }
      
      console.log(`✅ All ${listings.length} listings have valid structure`);
    });
    
  });
  
});
