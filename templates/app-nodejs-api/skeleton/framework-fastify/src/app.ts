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

  // A path that exists, asked for with a method it does not offer, is 405
  // with the methods it does offer; only a path that does not exist is 404.
  // Decided before the body is read, which would refuse some methods first.
  // `hasRoute` compares with the path as registered, so a route with
  // parameters needs its pattern looked up here instead of the request path.
  app.addHook('onRequest', async (request, reply) => {
    if (!request.is404) {
      return;
    }
    const path = request.url.split('?')[0];
    const allow = (['GET', 'POST', 'PUT', 'PATCH', 'DELETE'] as const).filter(
      (method) => app.hasRoute({ method, url: path }),
    );
    if (allow.length > 0) {
      await reply
        .header('allow', allow.join(', '))
        .status(405)
        .send({ error: 'Method Not Allowed' });
    }
  });

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
