import { Hono } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { requestId } from 'hono/request-id';
import { secureHeaders } from 'hono/secure-headers';
import { SERVICE_NAME } from './config';
import { log, requestLogger } from './logger';
import { api, isReady } from './routes/api';

export type AppEnv = { Bindings: Env };

export const app = new Hono<AppEnv>();

app.use(requestId());
app.use(requestLogger);
app.use(secureHeaders());

app.get('/health', (c) =>
  c.json({
    status: 'ok',
    service: SERVICE_NAME,
    environment: c.env.APP_ENV,
    timestamp: new Date().toISOString(),
  }),
);
app.get('/health/live', (c) => c.json({ alive: true }));
app.get('/health/ready', async (c) => {
  const ready = await isReady(c.env);
  return c.json({ ready }, ready ? 200 : 503);
});

app.route('/api', api);

app.notFound((c) => c.json({ error: 'Not Found' }, 404));

app.onError((error, c) => {
  if (error instanceof HTTPException) {
    return c.json({ error: error.message }, error.status);
  }
  log('error', 'unhandled error', {
    requestId: c.get('requestId'),
    error: error.message,
    stack: error.stack,
  });
  return c.json({ error: 'Internal Server Error' }, 500);
});
