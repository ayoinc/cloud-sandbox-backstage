import { buildApp } from './app';
import { config } from './config';

const app = buildApp();

// Lets requests in flight finish when the container is stopped.
for (const signal of ['SIGINT', 'SIGTERM'] as const) {
  process.on(signal, () => {
    app.log.info({ signal }, 'Shutting down');
    app.close().then(() => process.exit(0));
  });
}

// 0.0.0.0 makes the server reachable from outside a container.
app.listen({ port: config.port, host: '0.0.0.0' }).catch((error) => {
  app.log.error(error);
  process.exit(1);
});
