import { Hono } from 'hono';
import { bodyLimit } from 'hono/body-limit';
import { HTTPException } from 'hono/http-exception';
import { requestId } from 'hono/request-id';
import { secureHeaders } from 'hono/secure-headers';
import { SERVICE_NAME } from './config';
import type { Env } from './env';
import { type Logger, requestLogger } from './logger';
import { itemRoutes } from './routes/items';
import type { ItemStore } from './store';

export type AppOptions = {
  env: Env;
  logger: Logger;
  store: ItemStore;
  /** Whether the service accepts traffic; false while it shuts down. */
  isReady?: () => boolean;
};

export function createApp({
  env,
  logger,
  store,
  isReady = () => true,
}: AppOptions): Hono {
  const app = new Hono();

  app.use(requestId());
  app.use(requestLogger(logger));
  app.use(secureHeaders());
  app.use(bodyLimit({ maxSize: 1024 * 1024 }));

  app.get('/health', (c) =>
    c.json({
      status: 'ok',
      service: SERVICE_NAME,
      environment: env.APP_ENV,
      timestamp: new Date().toISOString(),
    }),
  );
  app.get('/health/live', (c) => c.json({ alive: true }));
  app.get('/health/ready', (c) => {
    const ready = isReady();
    return c.json({ ready }, ready ? 200 : 503);
  });

  app.route('/api/items', itemRoutes(store));

  app.notFound((c) => c.json({ error: 'Not Found' }, 404));

  app.onError((error, c) => {
    if (error instanceof HTTPException) {
      return c.json({ error: error.message }, error.status);
    }
    logger.error('unhandled error', {
      requestId: c.get('requestId'),
      error: error.message,
      stack: error.stack,
    });
    return c.json({ error: 'Internal Server Error' }, 500);
  });

  return app;
}
