/**
 * Type definitions for Agent Marketplace
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
  price: string;
  category?: string;
  condition?: 'new' | 'like-new' | 'excellent' | 'good' | 'fair' | 'poor';
  photos?: string[];
  sellerId?: string;
  sellerReputation?: number;
  createdAt?: string;
  updatedAt?: string;
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

export interface BrowseFilters {
  category?: string;
  maxPrice?: number;
  minPrice?: number;
  condition?: string;
  search?: string;
  limit?: number;
  offset?: number;
}

export interface PurchaseResponse {
  purchaseId: string;
  listingId: string;
  buyerId: string;
  sellerId: string;
  amount: string;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  escrowAddress?: string;
  createdAt: string;
}

export interface DeliveryConfirmation {
  listingId: string;
  purchaseId: string;
  confirmedBy: string;
  confirmedAt: string;
  fundsReleased: boolean;
  transactionHash?: string;
}

export interface AgentRegistration {
  agentId: string;
  name?: string;
  walletAddress?: string;
  capabilities?: string[];
  registeredAt: string;
}

export type ListingStatus = 'active' | 'pending' | 'sold' | 'cancelled';
export type PurchaseStatus = 'pending' | 'confirmed' | 'completed' | 'cancelled' | 'disputed';
export type ItemCondition = 'new' | 'like-new' | 'excellent' | 'good' | 'fair' | 'poor';
export type MarketplaceAction = 'list' | 'purchase' | 'release' | 'cancel' | 'dispute';

export interface APIError {
  error: string;
  message: string;
  statusCode: number;
  details?: any;
}

export interface APIResponse<T> {
  success: boolean;
  data?: T;
  error?: APIError;
}
