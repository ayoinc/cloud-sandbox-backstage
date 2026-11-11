import { createMiddleware } from 'hono/factory';
import { SERVICE_NAME } from './config';

const levels = ['debug', 'info', 'warn', 'error'] as const;
export type Level = (typeof levels)[number];
type Fields = Record<string, unknown>;

export type Logger = Record<Level, (message: string, fields?: Fields) => void>;

/**
 * A logger that writes one JSON line per entry to `write`, skipping entries
 * below `minimum`.
 */
export function createLogger(
  minimum: Level,
  write: (line: string) => void = console.log,
): Logger {
  const threshold = levels.indexOf(minimum);
  const at =
    (level: Level) =>
    (message: string, fields: Fields = {}) => {
      if (levels.indexOf(level) >= threshold) {
        write(
          JSON.stringify({
            time: new Date().toISOString(),
            level,
            service: SERVICE_NAME,
            message,
            ...fields,
          }),
        );
      }
    };
  return {
    debug: at('debug'),
    info: at('info'),
    warn: at('warn'),
    error: at('error'),
  };
}

/** Logs every request; probes are logged at debug level. */
export const requestLogger = (logger: Logger) =>
  createMiddleware(async (c, next) => {
    const start = performance.now();
    await next();
    const level = c.req.path.startsWith('/health') ? 'debug' : 'info';
    logger[level]('request', {
      requestId: c.get('requestId'),
      method: c.req.method,
      path: c.req.path,
      status: c.res.status,
      durationMs: Math.round(performance.now() - start),
    });
  });
