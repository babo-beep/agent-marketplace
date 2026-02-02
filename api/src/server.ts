import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import http from 'http';
import connectDB from './config/database';
import blockchainService from './services/blockchain';
import websocketService from './services/websocket';
import logger from './utils/logger';

// Import routes
import listingsRouter from './routes/listings';
import agentsRouter from './routes/agents';
import purchaseRouter from './routes/purchase';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet()); // Security headers
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' })); // CORS
app.use(express.json({ limit: '10mb' })); // JSON body parser with limit for images
app.use(express.urlencoded({ extended: true }));

// HTTP request logging
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('combined', { stream: { write: (msg) => logger.info(msg.trim()) } }));
}

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    websocketConnections: websocketService.getClientCount(),
  });
});

// API info endpoint
app.get('/', (_req: Request, res: Response) => {
  res.json({
    name: 'Agent Marketplace API',
    version: '1.0.0',
    description: 'Backend API for AI agent marketplace with blockchain escrow',
    endpoints: {
      listings: {
        'POST /listings': 'Create a new listing',
        'GET /listings': 'Browse/search listings',
        'GET /listings/:id': 'Get listing details',
        'PATCH /listings/:id': 'Update listing status',
      },
      agents: {
        'POST /agents/register': 'Register a new agent',
        'GET /agents/:id': 'Get agent details',
        'GET /agents/:id/reputation': 'Get agent reputation',
        'GET /agents': 'List all agents',
      },
      purchase: {
        'POST /purchase/request': 'Request a purchase',
        'POST /purchase/confirm': 'Confirm a purchase (seller)',
        'POST /purchase/release': 'Release funds (after delivery)',
        'GET /purchase/transactions': 'Get transaction history',
        'GET /purchase/transactions/:listingId': 'Get transaction for listing',
      },
      utility: {
        'GET /health': 'Health check',
        'GET /': 'API information',
      },
    },
  });
});

// API Routes
app.use('/listings', listingsRouter);
app.use('/agents', agentsRouter);
app.use('/purchase', purchaseRouter);

// 404 handler
app.use((_req: Request, res: Response) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handler
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  logger.error('Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// Create HTTP server
const server = http.createServer(app);

// Initialize services and start server
async function startServer() {
  try {
    logger.info('Starting Agent Marketplace API...');

    // Connect to MongoDB
    await connectDB();

    // Initialize blockchain service
    try {
      await blockchainService.initialize();
      
      // Start event indexing if contract address is configured
      if (process.env.CONTRACT_ADDRESS && process.env.CONTRACT_ADDRESS !== '0x0000000000000000000000000000000000000000') {
        await blockchainService.startEventIndexing();
        logger.info('Blockchain event indexing started');
      } else {
        logger.warn('Contract address not configured. Blockchain features disabled.');
      }
    } catch (error) {
      logger.error('Failed to initialize blockchain service:', error);
      logger.warn('API will run without blockchain integration');
    }

    // Initialize WebSocket service
    websocketService.initialize(server);

    // Start HTTP server
    server.listen(PORT, () => {
      logger.info(`🚀 Agent Marketplace API running on port ${PORT}`);
      logger.info(`📡 Environment: ${process.env.NODE_ENV || 'development'}`);
      logger.info(`🔗 Health check: http://localhost:${PORT}/health`);
      logger.info(`📚 API docs: http://localhost:${PORT}/`);
    });

    // Graceful shutdown
    const shutdown = async (signal: string) => {
      logger.info(`${signal} received. Shutting down gracefully...`);
      
      blockchainService.stopEventIndexing();
      
      server.close(() => {
        logger.info('HTTP server closed');
        process.exit(0);
      });

      // Force shutdown after 10 seconds
      setTimeout(() => {
        logger.error('Forced shutdown after timeout');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Start the server
startServer();

export default app;
