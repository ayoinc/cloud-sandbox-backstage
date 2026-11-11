import { createClient } from 'graphql-ws';
import { afterEach, describe, expect, it } from 'vitest';
import WebSocket from 'ws';
import { CREATE_PRODUCT, startTestServer, type TestServer } from './helpers.js';

let server: TestServer | undefined;
afterEach(async () => {
  await server?.close();
  server = undefined;
});

const webSocketUrl = (url: string) => `${url.replace('http', 'ws')}/graphql`;

describe('subscriptions', () => {
  it('pushes created products to subscribers over WebSocket when on', async () => {
    server = await startTestServer({ subscriptions: true });
    const client = createClient({ url: webSocketUrl(server.url), webSocketImpl: WebSocket, lazy: false });
    await new Promise<void>((resolve, reject) => {
      client.on('connected', () => resolve());
      client.on('error', reject);
    });

    const events = client.iterate<{ productCreated: { name: string } }>({
      query: 'subscription { productCreated { name } }',
    });
    const next = events.next();
    // Give the server time to register the subscription before the event.
    await new Promise(resolve => setTimeout(resolve, 100));
    await server.query(CREATE_PRODUCT, { variables: { input: { name: 'Widget', priceCents: 100 } } });

    expect((await next).value).toEqual({ data: { productCreated: { name: 'Widget' } } });
    await client.dispose();
  });

  it('has no Subscription type and accepts no WebSocket when off', async () => {
    server = await startTestServer({ subscriptions: false });

    const schema = await server.query('{ __schema { subscriptionType { name } } }');
    expect(schema.body.data).toEqual({ __schema: { subscriptionType: null } });

    const socket = new WebSocket(webSocketUrl(server.url), 'graphql-transport-ws');
    const outcome = await new Promise<string>(resolve => {
      socket.on('open', () => resolve('open'));
      socket.on('error', () => resolve('refused'));
    });
    socket.terminate();
    expect(outcome).toBe('refused');
  });
});
