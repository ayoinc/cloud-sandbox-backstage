import { createApp } from './app';
import { config } from './config';
import { logger } from './logger';

const server = createApp().listen(config.port, () => {
  logger.info(
    { port: config.port, environment: config.environment },
    'Server started',
  );
});

// Lets requests in flight finish when the container is stopped.
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    logger.info({ signal }, 'Shutting down');
    server.close(() => process.exit(0));
  });
}
