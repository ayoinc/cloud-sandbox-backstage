import { createHash, timingSafeEqual } from 'node:crypto';
import {
  hostHeaderValidation,
  localhostHostValidation,
} from '@modelcontextprotocol/sdk/server/middleware/hostHeaderValidation.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import express, { type Express, type RequestHandler } from 'express';
import { isLoopback, type Config } from './config.js';
import type { NoteStore } from './notes.js';
import { createServer } from './server.js';

const jsonRpcError = (code: number, message: string) => ({
  jsonrpc: '2.0' as const,
  error: { code, message },
  id: null,
});

const digest = (value: string): Buffer => createHash('sha256').update(value).digest();

/** Requires `Authorization: Bearer <token>`; the comparison takes constant time. */
function bearerAuth(token: string): RequestHandler {
  const expected = digest(token);
  return (req, res, next) => {
    const header = req.headers.authorization ?? '';
    const presented = header.startsWith('Bearer ') ? header.slice('Bearer '.length) : '';
    if (presented === '' || !timingSafeEqual(digest(presented), expected)) {
      res.set('WWW-Authenticate', 'Bearer').status(401).json(jsonRpcError(-32001, 'Unauthorized'));
      return;
    }
    next();
  };
}

/**
 * The Streamable HTTP transport in stateless mode: every POST to /mcp gets its
 * own server and transport, so any replica can answer any request and nothing
 * is kept between requests except the store.
 */
export function createHttpApp(config: Config, store: NoteStore): Express {
  const app = express();
  app.disable('x-powered-by');

  // Outside the checks below, so that probes can reach it by IP address.
  app.get('/healthz', (_req, res) => {
    res.json({ status: 'ok' });
  });

  // A page in a browser can make requests to a local server under a host name
  // it controls (DNS rebinding). Rejecting unknown Host headers prevents that.
  if (config.allowedHosts) {
    app.use('/mcp', hostHeaderValidation(config.allowedHosts));
  } else if (isLoopback(config.host)) {
    app.use('/mcp', localhostHostValidation());
  }
  if (config.authToken) {
    app.use('/mcp', bearerAuth(config.authToken));
  }
  app.use('/mcp', express.json({ limit: '1mb' }));

  app.post('/mcp', async (req, res) => {
    const server = createServer(store);
    const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
    res.on('close', () => {
      void transport.close();
      void server.close();
    });
    try {
      await server.connect(transport);
      await transport.handleRequest(req, res, req.body);
    } catch (error) {
      console.error('Failed to handle an MCP request:', error);
      if (!res.headersSent) {
        res.status(500).json(jsonRpcError(-32603, 'Internal server error'));
      }
    }
  });

  // Without sessions there is no stream to open with GET and nothing to end with DELETE.
  app.all('/mcp', (_req, res) => {
    res.set('Allow', 'POST').status(405).json(jsonRpcError(-32000, 'Method not allowed.'));
  });

  return app;
}
