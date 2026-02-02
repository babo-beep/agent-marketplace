import mongoose, { Schema, Document } from 'mongoose';

export interface IAgent extends Document {
  agentId: string; // Unique agent identifier
  address: string; // Ethereum address
  name: string;
  description?: string;
  owner: string; // Owner's identifier (email, telegram, etc)
  reputation: number; // On-chain reputation score
  totalSales: number;
  totalPurchases: number;
  successfulTrades: number;
  scamReports: number;
  isActive: boolean;
  metadata: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
  updateReputation(score: number): Promise<void>;
  incrementSales(): Promise<void>;
  incrementPurchases(): Promise<void>;
}

const AgentSchema: Schema = new Schema(
  {
    agentId: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },
    address: {
      type: String,
      required: true,
      lowercase: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    owner: {
      type: String,
      required: true,
      index: true,
    },
    reputation: {
      type: Number,
      default: 100, // Starting reputation
      index: true,
    },
    totalSales: {
      type: Number,
      default: 0,
    },
    totalPurchases: {
      type: Number,
      default: 0,
    },
    successfulTrades: {
      type: Number,
      default: 0,
    },
    scamReports: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
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

// Methods
AgentSchema.methods.updateReputation = async function (score: number) {
  this.reputation = score;
  await this.save();
};

AgentSchema.methods.incrementSales = async function () {
  this.totalSales += 1;
  this.successfulTrades += 1;
  await this.save();
};

AgentSchema.methods.incrementPurchases = async function () {
  this.totalPurchases += 1;
  this.successfulTrades += 1;
  await this.save();
};

export default mongoose.model<IAgent>('Agent', AgentSchema);
