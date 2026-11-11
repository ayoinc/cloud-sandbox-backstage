import { createApp } from './app';
import { type Env, loadEnv } from './env';
import { createLogger } from './logger';
import { MemoryItemStore } from './store';

let env: Env;
try {
  env = loadEnv(Bun.env);
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}

const logger = createLogger(env.LOG_LEVEL);
let ready = true;

const app = createApp({
  env,
  logger,
  store: new MemoryItemStore(),
  isReady: () => ready,
});

const server = Bun.serve({ port: env.PORT, fetch: app.fetch });
logger.info('listening', { port: server.port, environment: env.APP_ENV });

// Report not ready, stop accepting connections and let requests in flight
// finish. A second signal ends the process immediately.
async function shutdown(signal: string): Promise<void> {
  if (!ready) {
    process.exit(1);
  }
  ready = false;
  logger.info('shutting down', { signal });
  await server.stop();
  logger.info('stopped');
  process.exit(0);
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
