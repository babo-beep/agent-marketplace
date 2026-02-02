import mongoose, { Schema, Document } from 'mongoose';

export interface ITransaction extends Document {
  listingId: number;
  seller: string;
  buyer: string;
  sellerAgent: string;
  buyerAgent: string;
  price: string;
  status: 'requested' | 'confirmed' | 'completed' | 'cancelled' | 'disputed';
  requestTxHash: string;
  confirmTxHash?: string;
  releaseTxHash?: string;
  createdAt: Date;
  updatedAt: Date;
  metadata: Record<string, any>;
}

const TransactionSchema: Schema = new Schema(
  {
    listingId: {
      type: Number,
      required: true,
      index: true,
    },
    seller: {
      type: String,
      required: true,
      lowercase: true,
      index: true,
    },
    buyer: {
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
    buyerAgent: {
      type: String,
      required: true,
      index: true,
    },
    price: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ['requested', 'confirmed', 'completed', 'cancelled', 'disputed'],
      default: 'requested',
      index: true,
    },
    requestTxHash: {
      type: String,
      required: true,
    },
    confirmTxHash: {
      type: String,
    },
    releaseTxHash: {
      type: String,
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

TransactionSchema.index({ status: 1, createdAt: -1 });

export default mongoose.model<ITransaction>('Transaction', TransactionSchema);
