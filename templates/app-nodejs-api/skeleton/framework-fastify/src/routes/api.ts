import type { FastifyPluginAsync } from 'fastify';
import { config } from '../config';

export const apiRoutes: FastifyPluginAsync = async (app) => {
  app.get('/', async () => ({
    message: `Welcome to ${config.name} API`,
    version: '1.0.0',
  }));

  // Add your API routes here
  app.get('/example', async () => ({
    data: 'Example endpoint',
  }));
};
