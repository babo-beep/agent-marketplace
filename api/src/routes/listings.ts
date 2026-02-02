import { Router, Request, Response } from 'express';
import { body, query, validationResult } from 'express-validator';
import Listing from '../models/Listing';
import logger from '../utils/logger';
import websocketService from '../services/websocket';

const router = Router();

/**
 * POST /listings
 * Create a new listing
 */
router.post(
  '/',
  [
    body('seller').isEthereumAddress().withMessage('Invalid seller address'),
    body('sellerAgent').notEmpty().withMessage('Seller agent ID required'),
    body('title').trim().notEmpty().withMessage('Title required'),
    body('description').trim().notEmpty().withMessage('Description required'),
    body('price').isNumeric().withMessage('Price must be numeric'),
    body('category').notEmpty().withMessage('Category required'),
    body('txHash').notEmpty().withMessage('Transaction hash required'),
  ],
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const {
        listingId,
        seller,
        sellerAgent,
        title,
        description,
        price,
        category,
        location,
        images,
        txHash,
        metadata,
      } = req.body;

      // Check if listing already exists
      const existingListing = await Listing.findOne({ listingId });
      if (existingListing) {
        return res.status(409).json({ error: 'Listing already exists' });
      }

      const listing = await Listing.create({
        listingId,
        seller: seller.toLowerCase(),
        sellerAgent,
        title,
        description,
        price,
        category,
        location,
        images: images || [],
        txHash,
        metadata: metadata || {},
        status: 'active',
      });

      logger.info(`Listing created: ${listingId} - ${title}`);
      
      // Notify WebSocket clients
      websocketService.notifyListingCreated(listing);

      res.status(201).json({ success: true, listing });
    } catch (error) {
      logger.error('Error creating listing:', error);
      res.status(500).json({ error: 'Failed to create listing' });
    }
  }
);

/**
 * GET /listings
 * Browse and search listings
 */
router.get(
  '/',
  [
    query('status').optional().isIn(['active', 'pending', 'sold', 'cancelled']),
    query('category').optional().isString(),
    query('minPrice').optional().isNumeric(),
    query('maxPrice').optional().isNumeric(),
    query('search').optional().isString(),
    query('seller').optional().isEthereumAddress(),
    query('page').optional().isInt({ min: 1 }).toInt(),
    query('limit').optional().isInt({ min: 1, max: 100 }).toInt(),
  ],
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const {
        status,
        category,
        minPrice,
        maxPrice,
        search,
        seller,
        page = 1,
        limit = 20,
      } = req.query;

      // Build query
      const query: any = {};

      if (status) {
        query.status = status;
      } else {
        query.status = 'active'; // Default to active listings
      }

      if (category) {
        query.category = category;
      }

      if (seller) {
        query.seller = (seller as string).toLowerCase();
      }

      if (minPrice || maxPrice) {
        query.price = {};
        if (minPrice) {
          query.price.$gte = minPrice.toString();
        }
        if (maxPrice) {
          query.price.$lte = maxPrice.toString();
        }
      }

      if (search) {
        query.$text = { $search: search as string };
      }

      // Execute query with pagination
      const skip = (Number(page) - 1) * Number(limit);
      const [listings, total] = await Promise.all([
        Listing.find(query)
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(Number(limit)),
        Listing.countDocuments(query),
      ]);

      res.json({
        success: true,
        listings,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total,
          pages: Math.ceil(total / Number(limit)),
        },
      });
    } catch (error) {
      logger.error('Error fetching listings:', error);
      res.status(500).json({ error: 'Failed to fetch listings' });
    }
  }
);

/**
 * GET /listings/:id
 * Get listing details
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const listingId = parseInt(id);

    if (isNaN(listingId)) {
      return res.status(400).json({ error: 'Invalid listing ID' });
    }

    const listing = await Listing.findOne({ listingId });

    if (!listing) {
      return res.status(404).json({ error: 'Listing not found' });
    }

    res.json({ success: true, listing });
  } catch (error) {
    logger.error('Error fetching listing:', error);
    res.status(500).json({ error: 'Failed to fetch listing' });
  }
});

/**
 * PATCH /listings/:id
 * Update listing status
 */
router.patch(
  '/:id',
  [
    body('status').optional().isIn(['active', 'pending', 'sold', 'cancelled']),
    body('buyer').optional().isEthereumAddress(),
    body('buyerAgent').optional().isString(),
  ],
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { id } = req.params;
      const listingId = parseInt(id);

      if (isNaN(listingId)) {
        return res.status(400).json({ error: 'Invalid listing ID' });
      }

      const updateData: any = {};
      if (req.body.status) updateData.status = req.body.status;
      if (req.body.buyer) updateData.buyer = req.body.buyer.toLowerCase();
      if (req.body.buyerAgent) updateData.buyerAgent = req.body.buyerAgent;

      const listing = await Listing.findOneAndUpdate(
        { listingId },
        updateData,
        { new: true }
      );

      if (!listing) {
        return res.status(404).json({ error: 'Listing not found' });
      }

      logger.info(`Listing updated: ${listingId}`);
      res.json({ success: true, listing });
    } catch (error) {
      logger.error('Error updating listing:', error);
      res.status(500).json({ error: 'Failed to update listing' });
    }
  }
);

export default router;
