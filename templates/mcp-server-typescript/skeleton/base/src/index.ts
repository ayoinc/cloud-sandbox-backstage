#!/usr/bin/env node
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { ConfigError, loadConfig, type Config } from './config.js';
import { createHttpApp } from './http.js';
import { NoteStore } from './notes.js';
import { createServer, SERVER_NAME, SERVER_VERSION } from './server.js';

// Every log line goes to stderr: on the stdio transport stdout is the protocol.
const log = (message: string): void => {
  console.error(`[${SERVER_NAME}] ${message}`);
};

async function runStdio(store: NoteStore): Promise<void> {
  const server = createServer(store);
  await server.connect(new StdioServerTransport());
  log(`version ${SERVER_VERSION} serving on stdio`);
}

function runHttp(config: Config, store: NoteStore): void {
  const app = createHttpApp(config, store);
  const listener = app.listen(config.port, config.host, () => {
    log(
      `version ${SERVER_VERSION} serving Streamable HTTP on http://${config.host}:${String(config.port)}/mcp` +
        (config.authToken ? ' (bearer token required)' : ' (loopback only, no authentication)'),
    );
  });

  const shutdown = (signal: string): void => {
    log(`${signal} received, shutting down`);
    listener.close(() => process.exit(0));
    // Open event streams would keep the process alive.
    setTimeout(() => process.exit(0), 5000).unref();
  };
  process.once('SIGTERM', () => {
    shutdown('SIGTERM');
  });
  process.once('SIGINT', () => {
    shutdown('SIGINT');
  });
}

try {
  const config = loadConfig();
  const store = new NoteStore();
  if (config.transport === 'stdio') {
    await runStdio(store);
  } else {
    runHttp(config, store);
  }
} catch (error) {
  if (error instanceof ConfigError) {
    console.error(`Invalid configuration:\n${error.message}`);
  } else {
    console.error('The server failed to start:', error);
  }
  process.exit(1);
}
