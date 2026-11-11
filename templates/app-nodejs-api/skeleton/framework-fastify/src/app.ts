import compress from '@fastify/compress';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import Fastify, { type FastifyError, type FastifyInstance } from 'fastify';
import { config } from './config';
import { apiRoutes } from './routes/api';
import { healthRoutes } from './routes/health';

export function buildApp(): FastifyInstance {
  const app = Fastify({
    logger: { name: config.name, level: config.logLevel },
  });

  app.register(helmet);
  app.register(cors);
  app.register(compress);

  app.register(healthRoutes, { prefix: '/health' });
  app.register(apiRoutes, { prefix: '/api' });

  app.setNotFoundHandler((_request, reply) => {
    reply.status(404).send({ error: 'Not Found' });
  });

  // Fastify reports client errors such as a malformed body with a 4xx status.
  app.setErrorHandler<FastifyError>((error, request, reply) => {
    if (error.statusCode !== undefined && error.statusCode < 500) {
      reply.status(error.statusCode).send({ error: error.message });
      return;
    }
    request.log.error(error);
    reply.status(500).send({ error: 'Internal Server Error' });
  });

  return app;
}
