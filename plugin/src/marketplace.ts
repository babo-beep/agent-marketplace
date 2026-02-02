import axios, { AxiosInstance } from 'axios';
import { ethers } from 'ethers';

/**
 * Agent Marketplace Client
 * 
 * Provides methods for agents to interact with the marketplace:
 * - List items for sale (with owner confirmation)
 * - Browse listings
 * - Request purchases (with owner approval)
 * - Check reputation
 * - Confirm delivery and release escrow
 */

export interface MarketplaceConfig {
  apiUrl: string;
  agentId: string;
  walletAddress?: string;
  contractAddress?: string;
  providerUrl?: string;
}

export interface ListingData {
  id?: string;
  title: string;
  description: string;
  price: string; // in USDC or wei
  category?: string;
  condition?: string;
  photos?: string[]; // URLs or base64
  sellerId?: string;
  sellerReputation?: number;
  createdAt?: string;
  status?: 'active' | 'pending' | 'sold' | 'cancelled';
}

export interface PurchaseRequest {
  listingId: string;
  buyerId: string;
  buyerAgentId: string;
  amount: string;
  message?: string;
}

export interface AgentReputation {
  agentId: string;
  score: number;
  totalTransactions: number;
  successfulTransactions: number;
  disputes: number;
  lastUpdated: string;
}

export interface OwnerConfirmation {
  action: 'list' | 'purchase' | 'release' | 'cancel';
  details: any;
  confirmed: boolean;
  timestamp?: string;
}

export class MarketplaceClient {
  private api: AxiosInstance;
  private config: MarketplaceConfig;
  private provider?: ethers.JsonRpcProvider;
  private contract?: ethers.Contract;

  constructor(config: MarketplaceConfig) {
    this.config = config;
    
    this.api = axios.create({
      baseURL: config.apiUrl,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'X-Agent-ID': config.agentId,
      },
    });

    // Initialize blockchain provider if configured
    if (config.providerUrl && config.contractAddress) {
      this.initializeBlockchain();
    }
  }

  private initializeBlockchain() {
    try {
      this.provider = new ethers.JsonRpcProvider(this.config.providerUrl);
      
      // Basic escrow contract ABI (subset)
      const escrowABI = [
        'function listItem(string itemData, uint256 price, address seller) returns (uint256)',
        'function requestPurchase(uint256 listingId, address buyer, address agent) returns (bool)',
        'function confirmPurchase(uint256 listingId) returns (bool)',
        'function releaseFunds(uint256 listingId) returns (bool)',
        'function getAgentReputation(address agent) view returns (uint256)',
        'event ItemListed(uint256 indexed listingId, address seller, uint256 price)',
        'event PurchaseRequested(uint256 indexed listingId, address buyer, address agent)',
        'event FundsReleased(uint256 indexed listingId, address seller, uint256 amount)',
      ];

      this.contract = new ethers.Contract(
        this.config.contractAddress!,
        escrowABI,
        this.provider
      );
    } catch (error) {
      console.error('Failed to initialize blockchain:', error);
    }
  }

  /**
   * List an item for sale
   * This method should ONLY be called AFTER owner confirmation
   * 
   * @param listing Item details
   * @param ownerConfirmed Whether owner has approved the listing
   * @returns Created listing with ID
   */
  async listItem(
    listing: ListingData,
    ownerConfirmed: boolean = false
  ): Promise<ListingData> {
    if (!ownerConfirmed) {
      throw new Error(
        'OWNER_CONFIRMATION_REQUIRED: Agent must obtain owner approval before listing items'
      );
    }

    try {
      const response = await this.api.post('/listings', {
        ...listing,
        sellerId: this.config.agentId,
        agentId: this.config.agentId,
        confirmedByOwner: true,
      });

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to list item: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Browse marketplace listings with optional filters
   * No owner confirmation needed for browsing
   * 
   * @param filters Search/filter criteria
   * @returns Array of listings
   */
  async browseListings(filters?: {
    category?: string;
    maxPrice?: number;
    minPrice?: number;
    condition?: string;
    search?: string;
    limit?: number;
    offset?: number;
  }): Promise<ListingData[]> {
    try {
      const response = await this.api.get('/listings', {
        params: filters,
      });

      return response.data.listings || response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to browse listings: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Get details for a specific listing
   * 
   * @param listingId Listing ID
   * @returns Listing details
   */
  async getListingDetails(listingId: string): Promise<ListingData> {
    try {
      const response = await this.api.get(`/listings/${listingId}`);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to get listing: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Request to purchase an item
   * This method should ONLY be called AFTER owner confirmation
   * 
   * @param listingId Listing to purchase
   * @param ownerConfirmed Whether owner has approved the purchase
   * @returns Purchase request details
   */
  async requestPurchase(
    listingId: string,
    ownerConfirmed: boolean = false
  ): Promise<any> {
    if (!ownerConfirmed) {
      throw new Error(
        'OWNER_CONFIRMATION_REQUIRED: Agent must obtain owner approval before making purchases'
      );
    }

    try {
      const listing = await this.getListingDetails(listingId);
      
      const purchaseRequest: PurchaseRequest = {
        listingId,
        buyerId: this.config.walletAddress || this.config.agentId,
        buyerAgentId: this.config.agentId,
        amount: listing.price,
      };

      const response = await this.api.post('/purchase/request', {
        ...purchaseRequest,
        confirmedByOwner: true,
      });

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to request purchase: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Confirm delivery and release escrow funds
   * This method should ONLY be called AFTER owner confirms receipt
   * 
   * @param listingId Listing ID
   * @param ownerConfirmedDelivery Whether owner confirmed item received
   * @returns Transaction result
   */
  async confirmDelivery(
    listingId: string,
    ownerConfirmedDelivery: boolean = false
  ): Promise<any> {
    if (!ownerConfirmedDelivery) {
      throw new Error(
        'OWNER_CONFIRMATION_REQUIRED: Agent must obtain owner confirmation of delivery before releasing funds'
      );
    }

    try {
      const response = await this.api.post('/purchase/confirm-delivery', {
        listingId,
        confirmedByOwner: true,
        agentId: this.config.agentId,
      });

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to confirm delivery: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Check reputation for an agent
   * No owner confirmation needed
   * 
   * @param agentId Agent ID (defaults to current agent)
   * @returns Reputation data
   */
  async getReputation(agentId?: string): Promise<AgentReputation> {
    const targetAgentId = agentId || this.config.agentId;

    try {
      const response = await this.api.get(`/agents/${targetAgentId}/reputation`);
      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to get reputation: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Cancel a pending purchase request
   * Should ask owner for confirmation
   * 
   * @param listingId Listing ID
   * @param ownerConfirmed Owner approval
   */
  async cancelPurchase(
    listingId: string,
    ownerConfirmed: boolean = false
  ): Promise<any> {
    if (!ownerConfirmed) {
      throw new Error(
        'OWNER_CONFIRMATION_REQUIRED: Agent should confirm cancellation with owner'
      );
    }

    try {
      const response = await this.api.post('/purchase/cancel', {
        listingId,
        agentId: this.config.agentId,
        confirmedByOwner: true,
      });

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to cancel purchase: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Register agent in the marketplace
   * Should be called on first use
   */
  async registerAgent(agentData: {
    name?: string;
    walletAddress?: string;
    capabilities?: string[];
  }): Promise<any> {
    try {
      const response = await this.api.post('/agents/register', {
        agentId: this.config.agentId,
        ...agentData,
      });

      return response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to register agent: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Get current purchases (pending confirmations)
   */
  async getPendingPurchases(): Promise<any[]> {
    try {
      const response = await this.api.get('/purchase/pending', {
        params: { agentId: this.config.agentId },
      });

      return response.data.purchases || response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to get pending purchases: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }

  /**
   * Get agent's active listings
   */
  async getMyListings(): Promise<ListingData[]> {
    try {
      const response = await this.api.get('/listings/my-listings', {
        params: { agentId: this.config.agentId },
      });

      return response.data.listings || response.data;
    } catch (error) {
      if (axios.isAxiosError(error)) {
        throw new Error(`Failed to get my listings: ${error.response?.data?.message || error.message}`);
      }
      throw error;
    }
  }
}

/**
 * Helper function to create a formatted message for owner confirmation
 */
export function formatListingConfirmation(listing: ListingData): string {
  return `
📋 Listing Confirmation Required

Item: ${listing.title}
Description: ${listing.description}
Price: ${listing.price} USDC
Condition: ${listing.condition || 'Not specified'}
Category: ${listing.category || 'General'}

Please confirm you want to list this item.
Reply "yes" to confirm or "no" to cancel.
  `.trim();
}

/**
 * Helper function to format purchase confirmation message
 */
export function formatPurchaseConfirmation(listing: ListingData): string {
  return `
🛒 Purchase Confirmation Required

Listing: ${listing.title}
Price: ${listing.price} USDC
Condition: ${listing.condition || 'Not specified'}
Seller: ${listing.sellerId}
Seller Reputation: ${listing.sellerReputation || 'Unknown'}/100

Description:
${listing.description}

Funds will be held in escrow until you confirm delivery.

Do you want to proceed with this purchase?
Reply "yes" to confirm or "no" to cancel.
  `.trim();
}

/**
 * Helper function to format delivery confirmation message
 */
export function formatDeliveryConfirmation(listingId: string, listingTitle: string): string {
  return `
📦 Delivery Confirmation Required

Listing #${listingId}: ${listingTitle}

Have you received the item and verified it matches the description?

⚠️ Confirming will release funds from escrow to the seller.

Reply "yes" if received and correct, or "no" if there's an issue.
  `.trim();
}

export default MarketplaceClient;
