import type { Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StreamableHTTPClientTransport } from '@modelcontextprotocol/sdk/client/streamableHttp.js';
import { afterEach, describe, expect, it } from 'vitest';
import type { Config } from '../src/config.js';
import { createHttpApp } from '../src/http.js';
import { NoteStore } from '../src/notes.js';

const TOKEN = 'test-token-0123456789-0123456789-0123456789';

const INITIALIZE = {
  jsonrpc: '2.0',
  id: 1,
  method: 'initialize',
  params: {
    protocolVersion: '2025-06-18',
    capabilities: {},
    clientInfo: { name: 'test-client', version: '1.0.0' },
  },
};

describe('Streamable HTTP transport', () => {
  let listener: Server | undefined;

  const start = async (overrides: Partial<Config> = {}): Promise<string> => {
    const config: Config = {
      transport: 'http',
      host: '127.0.0.1',
      port: 0,
      authToken: TOKEN,
      allowedHosts: undefined,
      ...overrides,
    };
    const app = createHttpApp(config, new NoteStore());
    listener = await new Promise<Server>(resolve => {
      const server = app.listen(0, '127.0.0.1', () => {
        resolve(server);
      });
    });
    return `http://127.0.0.1:${String((listener.address() as AddressInfo).port)}`;
  };

  const post = (url: string, headers: Record<string, string> = {}): Promise<Response> =>
    fetch(`${url}/mcp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json, text/event-stream',
        ...headers,
      },
      body: JSON.stringify(INITIALIZE),
    });

  afterEach(async () => {
    await new Promise<void>(resolve => {
      if (!listener) {
        resolve();
        return;
      }
      listener.close(() => {
        resolve();
      });
      listener.closeAllConnections();
    });
    listener = undefined;
  });

  it('serves a client end to end, keeping notes between stateless requests', async () => {
    const url = await start();
    const client = new Client({ name: 'test-client', version: '1.0.0' });
    await client.connect(
      new StreamableHTTPClientTransport(new URL(`${url}/mcp`), {
        requestInit: { headers: { Authorization: `Bearer ${TOKEN}` } },
      }),
    );

    const added = await client.callTool({ name: 'add_note', arguments: { title: 'Over HTTP', body: 'It works' } });
    expect(added.isError).toBeFalsy();

    const found = await client.callTool({ name: 'search_notes', arguments: { query: 'http' } });
    expect(found.structuredContent).toMatchObject({ count: 1 });

    await client.close();
  });

  it('answers the health check without a token', async () => {
    const url = await start();
    const response = await fetch(`${url}/healthz`);
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ status: 'ok' });
  });

  it('rejects requests without the token or with a wrong one', async () => {
    const url = await start();

    const missing = await post(url);
    expect(missing.status).toBe(401);
    expect(missing.headers.get('www-authenticate')).toBe('Bearer');

    const wrong = await post(url, { Authorization: 'Bearer not-the-token' });
    expect(wrong.status).toBe(401);
  });

  it('accepts requests without a token when none is configured', async () => {
    const url = await start({ authToken: undefined });
    const response = await post(url);
    expect(response.status).toBe(200);
  });

  it('rejects a Host header that is not allowed', async () => {
    const url = await start({ allowedHosts: ['mcp.internal'] });
    const response = await post(url, { Authorization: `Bearer ${TOKEN}` });
    expect(response.status).toBe(403);
  });

  it('only allows POST on the MCP endpoint', async () => {
    const url = await start();
    const response = await fetch(`${url}/mcp`, { headers: { Authorization: `Bearer ${TOKEN}` } });
    expect(response.status).toBe(405);
    expect(response.headers.get('allow')).toBe('POST');
  });
});
