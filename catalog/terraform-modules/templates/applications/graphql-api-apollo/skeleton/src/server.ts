import http from 'node:http';
import { ApolloServer, type ApolloServerPlugin } from '@apollo/server';
import { ApolloServerPluginCacheControl } from '@apollo/server/plugin/cacheControl';
import { ApolloServerPluginLandingPageDisabled } from '@apollo/server/plugin/disabled';
import { ApolloServerPluginDrainHttpServer } from '@apollo/server/plugin/drainHttpServer';
import { ApolloServerPluginLandingPageLocalDefault } from '@apollo/server/plugin/landingPage/default';
import responseCachePlugin from '@apollo/server-plugin-response-cache';
import type { KeyValueCache } from '@apollo/utils.keyvaluecache';
import { expressMiddleware } from '@as-integrations/express5';
import cors from 'cors';
import express from 'express';
import { PubSub } from 'graphql-subscriptions';
import { useServer } from 'graphql-ws/use/ws';
import type { Knex } from 'knex';
import { WebSocketServer } from 'ws';
import { authenticate, createTokenVerifier } from './auth.js';
import type { Config } from './config.js';
import type { Context } from './context.js';
import { ProductRepository } from './db/products.js';
import { complexityPlugin } from './plugins/complexity.js';
import { createMetrics } from './plugins/metrics.js';
import { buildSchema } from './schema/index.js';

export interface ServerDependencies {
  db: Knex;
  /** Shared cache for responses. Without it each process caches in memory. */
  cache?: KeyValueCache<string>;
}

export interface Server {
  httpServer: http.Server;
  /** Stops accepting requests and waits for the running ones. */
  stop(): Promise<void>;
}

/**
 * Builds the HTTP server: GraphQL on /graphql (queries, mutations and, when
 * on, subscriptions over WebSocket), /healthz, /readyz and, when on, /metrics.
 * The caller decides where it listens.
 */
export async function createServer(config: Config, { db, cache }: ServerDependencies): Promise<Server> {
  const app = express();
  const httpServer = http.createServer(app);
  const schema = buildSchema({ subscriptions: config.subscriptions });

  const verifyToken = createTokenVerifier(config.auth);
  const products = new ProductRepository(db);
  const pubsub = new PubSub();
  const buildContext = async (authorization: unknown): Promise<Context> => ({
    viewer: await authenticate(verifyToken, authorization),
    auth: config.auth,
    products,
    pubsub,
  });

  const plugins: ApolloServerPlugin<Context>[] = [
    ApolloServerPluginDrainHttpServer({ httpServer }),
    config.playground ? ApolloServerPluginLandingPageLocalDefault() : ApolloServerPluginLandingPageDisabled(),
    complexityPlugin(schema, config.queryComplexityLimit),
  ];

  if (config.cache.enabled) {
    plugins.push(
      // Query results may be reused for this long, unless a field says otherwise.
      ApolloServerPluginCacheControl({ defaultMaxAge: config.cache.ttlSeconds }),
      // Responses that depend on the caller are cached per caller.
      responseCachePlugin<Context>({
        sessionId: async ({ contextValue }) => contextValue.viewer?.id ?? null,
      }),
    );
  }

  if (config.metrics) {
    const metrics = createMetrics();
    plugins.push(metrics.plugin);
    app.get('/metrics', async (_req, res) => {
      res.type(metrics.registry.contentType).send(await metrics.registry.metrics());
    });
  }

  if (config.subscriptions) {
    const webSocketServer = new WebSocketServer({ server: httpServer, path: '/graphql' });
    const subscriptions = useServer<{ authorization?: unknown }>(
      { schema, context: ctx => buildContext(ctx.connectionParams?.authorization) },
      webSocketServer,
    );
    plugins.push({
      async serverWillStart() {
        return {
          async drainServer() {
            await subscriptions.dispose();
          },
        };
      },
    });
  }

  const apollo = new ApolloServer<Context>({
    schema,
    plugins,
    cache,
    // Tools need introspection; production only offers it with the playground.
    introspection: config.playground || config.nodeEnv !== 'production',
  });
  await apollo.start();

  app.get('/healthz', (_req, res) => {
    res.json({ status: 'ok' });
  });
  app.get('/readyz', async (_req, res) => {
    try {
      await db.raw('select 1');
      res.json({ status: 'ok' });
    } catch {
      res.status(503).json({ status: 'database unavailable' });
    }
  });
  app.use(
    '/graphql',
    cors(),
    express.json(),
    expressMiddleware(apollo, { context: ({ req }) => buildContext(req.headers.authorization) }),
  );

  return { httpServer, stop: () => apollo.stop() };
}
