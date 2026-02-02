import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import Agent from '../models/Agent';
import blockchainService from '../services/blockchain';
import logger from '../utils/logger';

const router = Router();

/**
 * POST /agents/register
 * Register a new agent
 */
router.post(
  '/register',
  [
    body('agentId').notEmpty().withMessage('Agent ID required'),
    body('address').isEthereumAddress().withMessage('Invalid address'),
    body('name').trim().notEmpty().withMessage('Name required'),
    body('owner').notEmpty().withMessage('Owner identifier required'),
  ],
  async (req: Request, res: Response) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { agentId, address, name, description, owner, metadata } = req.body;

      // Check if agent already exists
      const existingAgent = await Agent.findOne({
        $or: [{ agentId }, { address: address.toLowerCase() }],
      });

      if (existingAgent) {
        return res.status(409).json({ error: 'Agent already registered' });
      }

      // Get on-chain reputation if available
      let reputation = 100; // Default
      try {
        reputation = await blockchainService.getAgentReputation(address);
      } catch (error) {
        logger.warn(`Could not fetch on-chain reputation for ${address}`);
      }

      const agent = await Agent.create({
        agentId,
        address: address.toLowerCase(),
        name,
        description,
        owner,
        reputation,
        metadata: metadata || {},
      });

      logger.info(`Agent registered: ${agentId} (${name})`);

      res.status(201).json({ success: true, agent });
    } catch (error) {
      logger.error('Error registering agent:', error);
      res.status(500).json({ error: 'Failed to register agent' });
    }
  }
);

/**
 * GET /agents/:id/reputation
 * Get agent reputation (synced from blockchain)
 */
router.get('/:id/reputation', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    // Find agent by ID or address
    const agent = await Agent.findOne({
      $or: [{ agentId: id }, { address: id.toLowerCase() }],
    });

    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    // Sync with blockchain
    try {
      const onChainReputation = await blockchainService.getAgentReputation(agent.address);
      if (onChainReputation !== agent.reputation) {
        agent.reputation = onChainReputation;
        await agent.save();
        logger.info(`Synced reputation for ${agent.agentId}: ${onChainReputation}`);
      }
    } catch (error) {
      logger.warn(`Could not sync reputation for ${agent.agentId}`);
    }

    res.json({
      success: true,
      agent: {
        agentId: agent.agentId,
        name: agent.name,
        address: agent.address,
        reputation: agent.reputation,
        totalSales: agent.totalSales,
        totalPurchases: agent.totalPurchases,
        successfulTrades: agent.successfulTrades,
        scamReports: agent.scamReports,
      },
    });
  } catch (error) {
    logger.error('Error fetching agent reputation:', error);
    res.status(500).json({ error: 'Failed to fetch agent reputation' });
  }
});

/**
 * GET /agents/:id
 * Get full agent details
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const agent = await Agent.findOne({
      $or: [{ agentId: id }, { address: id.toLowerCase() }],
    });

    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }

    res.json({ success: true, agent });
  } catch (error) {
    logger.error('Error fetching agent:', error);
    res.status(500).json({ error: 'Failed to fetch agent' });
  }
});

/**
 * GET /agents
 * List all agents
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const { page = 1, limit = 20, sortBy = 'reputation' } = req.query;

    const skip = (Number(page) - 1) * Number(limit);
    const sort: any = {};
    
    if (sortBy === 'reputation') {
      sort.reputation = -1;
    } else if (sortBy === 'trades') {
      sort.successfulTrades = -1;
    } else {
      sort.createdAt = -1;
    }

    const [agents, total] = await Promise.all([
      Agent.find({ isActive: true })
        .sort(sort)
        .skip(skip)
        .limit(Number(limit)),
      Agent.countDocuments({ isActive: true }),
    ]);

    res.json({
      success: true,
      agents,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit)),
      },
    });
  } catch (error) {
    logger.error('Error fetching agents:', error);
    res.status(500).json({ error: 'Failed to fetch agents' });
  }
});

export default router;
