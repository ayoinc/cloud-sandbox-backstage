import { createMiddleware } from 'hono/factory';

type Level = 'debug' | 'info' | 'warn' | 'error';

/**
 * Writes one JSON line. Workers Logs indexes the fields of JSON log lines, so
 * they can be filtered on in the dashboard and in `wrangler tail`.
 */
export function log(
  level: Level,
  message: string,
  fields: Record<string, unknown> = {},
): void {
  console[level](JSON.stringify({ level, message, ...fields }));
}

/** Logs every request with its status and duration. */
export const requestLogger = createMiddleware(async (c, next) => {
  const start = performance.now();
  await next();
  log('info', 'request', {
    requestId: c.get('requestId'),
    method: c.req.method,
    path: c.req.path,
    status: c.res.status,
    durationMs: Math.round(performance.now() - start),
  });
});
