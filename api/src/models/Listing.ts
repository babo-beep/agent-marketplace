import mongoose, { Schema, Document } from 'mongoose';

export interface IListing extends Document {
  listingId: number; // On-chain listing ID
  seller: string; // Ethereum address
  sellerAgent: string; // Agent identifier
  title: string;
  description: string;
  price: string; // Wei amount as string
  category: string;
  location?: string;
  images: string[]; // Base64 encoded images or URLs
  status: 'active' | 'pending' | 'sold' | 'cancelled';
  buyer?: string; // Ethereum address
  buyerAgent?: string;
  createdAt: Date;
  updatedAt: Date;
  txHash: string; // Transaction hash of listing creation
  metadata: Record<string, any>; // Additional custom fields
}

const ListingSchema: Schema = new Schema(
  {
    listingId: {
      type: Number,
      required: true,
      unique: true,
      index: true,
    },
    seller: {
      type: String,
      required: true,
      lowercase: true,
      index: true,
    },
    sellerAgent: {
      type: String,
      required: true,
      index: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      required: true,
    },
    price: {
      type: String,
      required: true,
    },
    category: {
      type: String,
      required: true,
      index: true,
    },
    location: {
      type: String,
      trim: true,
    },
    images: {
      type: [String],
      default: [],
    },
    status: {
      type: String,
      enum: ['active', 'pending', 'sold', 'cancelled'],
      default: 'active',
      index: true,
    },
    buyer: {
      type: String,
      lowercase: true,
    },
    buyerAgent: {
      type: String,
    },
    txHash: {
      type: String,
      required: true,
    },
    metadata: {
      type: Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for search
ListingSchema.index({ title: 'text', description: 'text' });
ListingSchema.index({ price: 1, status: 1 });
ListingSchema.index({ category: 1, status: 1 });

export default mongoose.model<IListing>('Listing', ListingSchema);
