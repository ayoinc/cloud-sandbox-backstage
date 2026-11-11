import type { FastifyPluginAsync } from 'fastify';
import { config } from '../config';

export const healthRoutes: FastifyPluginAsync = async (app) => {
  app.get('/', async () => ({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: config.name,
    environment: config.environment,
  }));

  // Add readiness checks here (database, cache, etc.)
  app.get('/ready', async () => ({ ready: true }));

  app.get('/live', async () => ({ alive: true }));
};
