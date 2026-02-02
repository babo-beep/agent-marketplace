import WebSocket, { WebSocketServer } from 'ws';
import { Server } from 'http';
import logger from '../utils/logger';

export interface NotificationMessage {
  type: 'listing_created' | 'purchase_requested' | 'purchase_confirmed' | 'funds_released' | 'reputation_updated';
  data: any;
  timestamp: number;
}

class WebSocketService {
  private wss: WebSocketServer | null = null;
  private clients: Set<WebSocket> = new Set();

  initialize(server: Server): void {
    const wsPort = parseInt(process.env.WS_PORT || '3001');
    const wsEnabled = process.env.WS_ENABLED !== 'false';

    if (!wsEnabled) {
      logger.info('WebSocket disabled via configuration');
      return;
    }

    this.wss = new WebSocketServer({ server });

    this.wss.on('connection', (ws: WebSocket) => {
      this.clients.add(ws);
      logger.info(`WebSocket client connected. Total clients: ${this.clients.size}`);

      ws.on('message', (message: string) => {
        try {
          const data = JSON.parse(message.toString());
          logger.debug('Received WebSocket message:', data);
          
          // Handle client messages (ping, subscribe, etc.)
          if (data.type === 'ping') {
            ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
          }
        } catch (error) {
          logger.error('Error handling WebSocket message:', error);
        }
      });

      ws.on('close', () => {
        this.clients.delete(ws);
        logger.info(`WebSocket client disconnected. Total clients: ${this.clients.size}`);
      });

      ws.on('error', (error) => {
        logger.error('WebSocket error:', error);
        this.clients.delete(ws);
      });

      // Send welcome message
      ws.send(
        JSON.stringify({
          type: 'connected',
          message: 'Connected to Agent Marketplace WebSocket',
          timestamp: Date.now(),
        })
      );
    });

    logger.info(`WebSocket server initialized on port ${wsPort}`);
  }

  broadcast(message: NotificationMessage): void {
    if (!this.wss) return;

    const payload = JSON.stringify(message);
    let sent = 0;

    this.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(payload);
        sent++;
      }
    });

    logger.debug(`Broadcast message to ${sent} clients:`, message.type);
  }

  notifyListingCreated(listing: any): void {
    this.broadcast({
      type: 'listing_created',
      data: listing,
      timestamp: Date.now(),
    });
  }

  notifyPurchaseRequested(transaction: any): void {
    this.broadcast({
      type: 'purchase_requested',
      data: transaction,
      timestamp: Date.now(),
    });
  }

  notifyPurchaseConfirmed(transaction: any): void {
    this.broadcast({
      type: 'purchase_confirmed',
      data: transaction,
      timestamp: Date.now(),
    });
  }

  notifyFundsReleased(transaction: any): void {
    this.broadcast({
      type: 'funds_released',
      data: transaction,
      timestamp: Date.now(),
    });
  }

  notifyReputationUpdated(agent: any): void {
    this.broadcast({
      type: 'reputation_updated',
      data: agent,
      timestamp: Date.now(),
    });
  }

  getClientCount(): number {
    return this.clients.size;
  }
}

export default new WebSocketService();
