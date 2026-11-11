import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { vi } from 'vitest';
import type { Features } from './api';
import { App } from './App';

export const allOff: Features = {
  productManagement: false,
  payments: false,
  search: false,
  reviews: false,
  inventory: false,
  analytics: false,
  caching: false,
};

export const mug = { id: 'p1', name: 'Mug', description: 'A stoneware mug', priceCents: 1400, imageUrl: null, available: true };
export const lamp = { id: 'p2', name: 'Lamp', description: 'A desk lamp', priceCents: 3900, imageUrl: null, available: true };

export interface Call {
  method: string;
  path: string;
  body?: unknown;
  authorization?: string | null;
}

type Reply = unknown | ((call: Call) => unknown);

/**
 * Replaces fetch with a stand-in for the API. `replies` maps "METHOD /path"
 * (below /api/v1) to the JSON to answer with; /config answers with `features`.
 * Returns the calls that were made.
 */
export function mockApi(features: Partial<Features>, replies: Record<string, Reply> = {}): Call[] {
  const calls: Call[] = [];
  const all: Record<string, Reply> = {
    'GET /config': { features: { ...allOff, ...features } },
    'GET /products': { products: [mug, lamp] },
    ...replies,
  };
  vi.stubGlobal(
    'fetch',
    vi.fn(async (url: string, init: RequestInit = {}) => {
      const call: Call = {
        method: init.method ?? 'GET',
        path: url.replace('/api/v1', ''),
        body: init.body ? JSON.parse(init.body as string) : undefined,
        authorization: new Headers(init.headers).get('authorization'),
      };
      calls.push(call);
      const reply = all[`${call.method} ${call.path}`];
      if (reply === undefined) {
        return new Response(JSON.stringify({ error: `No reply for ${call.method} ${call.path}` }), { status: 404 });
      }
      const body = typeof reply === 'function' ? reply(call) : reply;
      return new Response(JSON.stringify(body), { status: 200 });
    }),
  );
  return calls;
}

/** Renders the whole application at the given address. */
export function renderApp(path = '/') {
  return render(
    <MemoryRouter initialEntries={[path]}>
      <App />
    </MemoryRouter>,
  );
}
