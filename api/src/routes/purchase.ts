import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import Listing from '../models/Listing';
import Transaction from '../models/Transaction';
import Agent from '../models/Agent';
import logger from '../utils/logger';
import websocketService from '../services/websocket';

const router = Router();

/**
 * POST /purchase/request
 * Initiate a purchase request
 */
router.post(
  '/request',
  [
    body('listingId').isInt().withMessage('Listing ID must be an integer'),
    body('buyer').isEthereumAddress().withMessage('Invalid buyer address'),
    body('buyerAgent').notEmpty().withMessage('Buyer agent ID required'),
    body('txHash').notEmpty().withMessage('Transaction hash required'),
  ],
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { listingId, buyer, buyerAgent, txHash } = req.body;

      // Find the listing
      const listing = await Listing.findOne({ listingId });
      if (!listing) {
        return res.status(404).json({ error: 'Listing not found' });
      }

      // Check if listing is active
      if (listing.status !== 'active') {
        return res.status(400).json({ error: 'Listing is not active' });
      }

      // Check if buyer is not the seller
      if (listing.seller.toLowerCase() === buyer.toLowerCase()) {
        return res.status(400).json({ error: 'Cannot purchase your own listing' });
      }

      // Check if transaction already exists
      const existingTransaction = await Transaction.findOne({
        listingId,
        status: { $in: ['requested', 'confirmed'] },
      });

      if (existingTransaction) {
        return res.status(409).json({
          error: 'Purchase already in progress',
          transaction: existingTransaction,
        });
      }

      // Update listing status
      listing.status = 'pending';
      listing.buyer = buyer.toLowerCase();
      listing.buyerAgent = buyerAgent;
      await listing.save();

      // Create transaction record
      const transaction = await Transaction.create({
        listingId,
        seller: listing.seller,
        buyer: buyer.toLowerCase(),
        sellerAgent: listing.sellerAgent,
        buyerAgent,
        price: listing.price,
        status: 'requested',
        requestTxHash: txHash,
      });

      logger.info(`Purchase requested: Listing ${listingId} by ${buyerAgent}`);

      // Notify WebSocket clients
      websocketService.notifyPurchaseRequested(transaction);

      res.status(201).json({
        success: true,
        message: 'Purchase request created. Waiting for seller confirmation.',
        transaction,
      });
    } catch (error) {
      logger.error('Error creating purchase request:', error);
      res.status(500).json({ error: 'Failed to create purchase request' });
    }
  }
);

/**
 * POST /purchase/confirm
 * Confirm a purchase (called after owner approval)
 */
router.post(
  '/confirm',
  [
    body('listingId').isInt().withMessage('Listing ID must be an integer'),
    body('txHash').notEmpty().withMessage('Transaction hash required'),
  ],
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { listingId, txHash } = req.body;

      // Find the transaction
      const transaction = await Transaction.findOne({
        listingId,
        status: 'requested',
      });

      if (!transaction) {
        return res.status(404).json({
          error: 'No pending purchase request found for this listing',
        });
      }

      // Update transaction
      transaction.status = 'confirmed';
      transaction.confirmTxHash = txHash;
      await transaction.save();

      logger.info(`Purchase confirmed: Listing ${listingId}`);

      // Notify WebSocket clients
      websocketService.notifyPurchaseConfirmed(transaction);

      res.json({
        success: true,
        message: 'Purchase confirmed. Funds are in escrow.',
        transaction,
      });
    } catch (error) {
      logger.error('Error confirming purchase:', error);
      res.status(500).json({ error: 'Failed to confirm purchase' });
    }
  }
);

/**
 * POST /purchase/release
 * Release funds after delivery confirmation
 */
router.post(
  '/release',
  [
    body('listingId').isInt().withMessage('Listing ID must be an integer'),
    body('txHash').notEmpty().withMessage('Transaction hash required'),
  ],
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { listingId, txHash } = req.body;

      // Find the transaction
      const transaction = await Transaction.findOne({
        listingId,
        status: 'confirmed',
      });

      if (!transaction) {
        return res.status(404).json({
          error: 'No confirmed purchase found for this listing',
        });
      }

      // Update transaction
      transaction.status = 'completed';
      transaction.releaseTxHash = txHash;
      await transaction.save();

      // Update listing
      await Listing.findOneAndUpdate(
        { listingId },
        { status: 'sold' }
      );

      // Update agent statistics
      const sellerAgent = await Agent.findOne({ agentId: transaction.sellerAgent });
      if (sellerAgent) {
        await sellerAgent.incrementSales();
      }

      const buyerAgent = await Agent.findOne({ agentId: transaction.buyerAgent });
      if (buyerAgent) {
        await buyerAgent.incrementPurchases();
      }

      logger.info(`Funds released: Listing ${listingId}`);

      // Notify WebSocket clients
      websocketService.notifyFundsReleased(transaction);

      res.json({
        success: true,
        message: 'Funds released successfully. Transaction complete.',
        transaction,
      });
    } catch (error) {
      logger.error('Error releasing funds:', error);
      res.status(500).json({ error: 'Failed to release funds' });
    }
  }
);

/**
 * GET /purchase/transactions
 * Get transaction history
 */
router.get('/transactions', async (req: Request, res: Response) => {
  try {
    const { status, seller, buyer, page = 1, limit = 20 } = req.query;

    const query: any = {};

    if (status) {
      query.status = status;
    }

    if (seller) {
      query.seller = (seller as string).toLowerCase();
    }

    if (buyer) {
      query.buyer = (buyer as string).toLowerCase();
    }

    const skip = (Number(page) - 1) * Number(limit);
    const [transactions, total] = await Promise.all([
      Transaction.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit)),
      Transaction.countDocuments(query),
    ]);

    res.json({
      success: true,
      transactions,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit)),
      },
    });
  } catch (error) {
    logger.error('Error fetching transactions:', error);
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

/**
 * GET /purchase/transactions/:listingId
 * Get transaction for specific listing
 */
router.get('/transactions/:listingId', async (req: Request, res: Response) => {
  try {
    const { listingId } = req.params;
    const id = parseInt(listingId);

    if (isNaN(id)) {
      return res.status(400).json({ error: 'Invalid listing ID' });
    }

    const transaction = await Transaction.findOne({ listingId: id }).sort({ createdAt: -1 });

    if (!transaction) {
      return res.status(404).json({ error: 'Transaction not found' });
    }

    res.json({ success: true, transaction });
  } catch (error) {
    logger.error('Error fetching transaction:', error);
    res.status(500).json({ error: 'Failed to fetch transaction' });
  }
});

export default router;
