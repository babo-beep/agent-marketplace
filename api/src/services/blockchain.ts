import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';
import Listing from '../models/Listing';
import Agent from '../models/Agent';
import Transaction from '../models/Transaction';
import logger from '../utils/logger';

class BlockchainService {
  private provider: ethers.JsonRpcProvider;
  private contract: ethers.Contract | null = null;
  private contractAddress: string;
  private lastProcessedBlock: number;
  private isIndexing: boolean = false;

  constructor() {
    const rpcUrl = process.env.RPC_URL || 'http://localhost:8545';
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.contractAddress = process.env.CONTRACT_ADDRESS || '';
    this.lastProcessedBlock = parseInt(process.env.START_BLOCK || '0');
  }

  async initialize(): Promise<void> {
    try {
      // Load contract ABI
      const abiPath = path.join(
        __dirname,
        '../../../',
        process.env.CONTRACT_ABI_PATH || 'contracts/out/AgentMarketplace.sol/AgentMarketplace.json'
      );

      let abi: any[];
      if (fs.existsSync(abiPath)) {
        const contractJson = JSON.parse(fs.readFileSync(abiPath, 'utf-8'));
        abi = contractJson.abi;
      } else {
        logger.warn(`ABI file not found at ${abiPath}, using minimal ABI`);
        // Minimal ABI for basic functionality
        abi = [
          'event ItemListed(uint256 indexed listingId, address indexed seller, uint256 price, string itemData)',
          'event PurchaseRequested(uint256 indexed listingId, address indexed buyer, address indexed agent)',
          'event PurchaseConfirmed(uint256 indexed listingId, address indexed seller)',
          'event FundsReleased(uint256 indexed listingId, address indexed seller, address indexed buyer)',
          'event ReputationUpdated(address indexed agent, int256 change, uint256 newReputation)',
          'function listItem(string memory itemData, uint256 price, address seller) external returns (uint256)',
          'function requestPurchase(uint256 listingId, address buyer, address agent) external payable',
          'function confirmPurchase(uint256 listingId) external',
          'function releaseFunds(uint256 listingId) external',
          'function getAgentReputation(address agent) external view returns (uint256)',
          'function getListing(uint256 listingId) external view returns (tuple(address seller, uint256 price, bool isActive, address buyer, bool confirmed, bool completed))',
        ];
      }

      // Initialize contract
      this.contract = new ethers.Contract(this.contractAddress, abi, this.provider);
      logger.info(`Blockchain service initialized with contract at ${this.contractAddress}`);
    } catch (error) {
      logger.error('Failed to initialize blockchain service:', error);
      throw error;
    }
  }

  async startEventIndexing(): Promise<void> {
    if (this.isIndexing) {
      logger.warn('Event indexing already running');
      return;
    }

    if (!this.contract) {
      throw new Error('Contract not initialized');
    }

    this.isIndexing = true;
    logger.info('Starting event indexing...');

    const pollInterval = parseInt(process.env.POLL_INTERVAL_MS || '5000');

    const indexEvents = async () => {
      try {
        const currentBlock = await this.provider.getBlockNumber();
        
        if (currentBlock > this.lastProcessedBlock) {
          await this.processEvents(this.lastProcessedBlock + 1, currentBlock);
          this.lastProcessedBlock = currentBlock;
        }
      } catch (error) {
        logger.error('Error indexing events:', error);
      }

      if (this.isIndexing) {
        setTimeout(indexEvents, pollInterval);
      }
    };

    indexEvents();
  }

  stopEventIndexing(): void {
    this.isIndexing = false;
    logger.info('Event indexing stopped');
  }

  private async processEvents(fromBlock: number, toBlock: number): Promise<void> {
    if (!this.contract) return;

    try {
      logger.debug(`Processing events from block ${fromBlock} to ${toBlock}`);

      // ItemListed events
      const itemListedFilter = this.contract.filters.ItemListed();
      const itemListedEvents = await this.contract.queryFilter(itemListedFilter, fromBlock, toBlock);
      
      for (const event of itemListedEvents) {
        await this.handleItemListed(event);
      }

      // PurchaseRequested events
      const purchaseRequestedFilter = this.contract.filters.PurchaseRequested();
      const purchaseRequestedEvents = await this.contract.queryFilter(purchaseRequestedFilter, fromBlock, toBlock);
      
      for (const event of purchaseRequestedEvents) {
        await this.handlePurchaseRequested(event);
      }

      // PurchaseConfirmed events
      const purchaseConfirmedFilter = this.contract.filters.PurchaseConfirmed();
      const purchaseConfirmedEvents = await this.contract.queryFilter(purchaseConfirmedFilter, fromBlock, toBlock);
      
      for (const event of purchaseConfirmedEvents) {
        await this.handlePurchaseConfirmed(event);
      }

      // FundsReleased events
      const fundsReleasedFilter = this.contract.filters.FundsReleased();
      const fundsReleasedEvents = await this.contract.queryFilter(fundsReleasedFilter, fromBlock, toBlock);
      
      for (const event of fundsReleasedEvents) {
        await this.handleFundsReleased(event);
      }

      // ReputationUpdated events
      const reputationUpdatedFilter = this.contract.filters.ReputationUpdated();
      const reputationUpdatedEvents = await this.contract.queryFilter(reputationUpdatedFilter, fromBlock, toBlock);
      
      for (const event of reputationUpdatedEvents) {
        await this.handleReputationUpdated(event);
      }

      logger.info(`Processed ${itemListedEvents.length + purchaseRequestedEvents.length + purchaseConfirmedEvents.length + fundsReleasedEvents.length + reputationUpdatedEvents.length} events from blocks ${fromBlock}-${toBlock}`);
    } catch (error) {
      logger.error('Error processing events:', error);
    }
  }

  private async handleItemListed(event: any): Promise<void> {
    try {
      const { listingId, seller, price, itemData } = event.args;
      const txHash = event.transactionHash;

      logger.info(`New listing: ${listingId} by ${seller}`);

      // Parse itemData (assumed to be JSON string)
      let parsedData: any = {};
      try {
        parsedData = JSON.parse(itemData);
      } catch {
        parsedData = { raw: itemData };
      }

      // Create or update listing in database
      await Listing.findOneAndUpdate(
        { listingId: Number(listingId) },
        {
          listingId: Number(listingId),
          seller: seller.toLowerCase(),
          sellerAgent: parsedData.agentId || 'unknown',
          title: parsedData.title || 'Untitled',
          description: parsedData.description || '',
          price: price.toString(),
          category: parsedData.category || 'other',
          location: parsedData.location,
          images: parsedData.images || [],
          status: 'active',
          txHash,
          metadata: parsedData,
        },
        { upsert: true, new: true }
      );
    } catch (error) {
      logger.error('Error handling ItemListed event:', error);
    }
  }

  private async handlePurchaseRequested(event: any): Promise<void> {
    try {
      const { listingId, buyer, agent } = event.args;
      const txHash = event.transactionHash;

      logger.info(`Purchase requested for listing ${listingId} by ${buyer}`);

      // Update listing status
      const listing = await Listing.findOneAndUpdate(
        { listingId: Number(listingId) },
        {
          status: 'pending',
          buyer: buyer.toLowerCase(),
          buyerAgent: agent,
        },
        { new: true }
      );

      if (listing) {
        // Create transaction record
        await Transaction.create({
          listingId: Number(listingId),
          seller: listing.seller,
          buyer: buyer.toLowerCase(),
          sellerAgent: listing.sellerAgent,
          buyerAgent: agent,
          price: listing.price,
          status: 'requested',
          requestTxHash: txHash,
        });
      }
    } catch (error) {
      logger.error('Error handling PurchaseRequested event:', error);
    }
  }

  private async handlePurchaseConfirmed(event: any): Promise<void> {
    try {
      const { listingId } = event.args;
      const txHash = event.transactionHash;

      logger.info(`Purchase confirmed for listing ${listingId}`);

      // Update transaction
      await Transaction.findOneAndUpdate(
        { listingId: Number(listingId), status: 'requested' },
        {
          status: 'confirmed',
          confirmTxHash: txHash,
        }
      );
    } catch (error) {
      logger.error('Error handling PurchaseConfirmed event:', error);
    }
  }

  private async handleFundsReleased(event: any): Promise<void> {
    try {
      const { listingId } = event.args;
      const txHash = event.transactionHash;

      logger.info(`Funds released for listing ${listingId}`);

      // Update listing status
      const listing = await Listing.findOneAndUpdate(
        { listingId: Number(listingId) },
        { status: 'sold' },
        { new: true }
      );

      // Update transaction
      await Transaction.findOneAndUpdate(
        { listingId: Number(listingId), status: 'confirmed' },
        {
          status: 'completed',
          releaseTxHash: txHash,
        }
      );

      // Update agent statistics
      if (listing) {
        const sellerAgent = await Agent.findOne({ agentId: listing.sellerAgent });
        if (sellerAgent) {
          await sellerAgent.incrementSales();
        }

        const buyerAgent = await Agent.findOne({ agentId: listing.buyerAgent });
        if (buyerAgent) {
          await buyerAgent.incrementPurchases();
        }
      }
    } catch (error) {
      logger.error('Error handling FundsReleased event:', error);
    }
  }

  private async handleReputationUpdated(event: any): Promise<void> {
    try {
      const { agent, change, newReputation } = event.args;

      logger.info(`Reputation updated for ${agent}: ${change} (new: ${newReputation})`);

      // Update agent reputation
      await Agent.findOneAndUpdate(
        { address: agent.toLowerCase() },
        { reputation: Number(newReputation) },
        { new: true }
      );
    } catch (error) {
      logger.error('Error handling ReputationUpdated event:', error);
    }
  }

  // Contract interaction methods
  async getAgentReputation(agentAddress: string): Promise<number> {
    if (!this.contract) throw new Error('Contract not initialized');
    
    try {
      const reputation = await this.contract.getAgentReputation(agentAddress);
      return Number(reputation);
    } catch (error) {
      logger.error('Error getting agent reputation:', error);
      throw error;
    }
  }

  async getListing(listingId: number): Promise<any> {
    if (!this.contract) throw new Error('Contract not initialized');
    
    try {
      const listing = await this.contract.getListing(listingId);
      return {
        seller: listing[0],
        price: listing[1].toString(),
        isActive: listing[2],
        buyer: listing[3],
        confirmed: listing[4],
        completed: listing[5],
      };
    } catch (error) {
      logger.error('Error getting listing:', error);
      throw error;
    }
  }

  getProvider(): ethers.JsonRpcProvider {
    return this.provider;
  }

  getContract(): ethers.Contract {
    if (!this.contract) throw new Error('Contract not initialized');
    return this.contract;
  }
}

export default new BlockchainService();
