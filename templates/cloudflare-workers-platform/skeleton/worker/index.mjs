// Worker entry point. Terraform uploads this file as it is: there is no build
// step, so it must stay a single ES module without imports from npm.
//
// Bindings (declared in main.tf):
//   BUCKET       R2 bucket for files
//   DB or KV     D1 database or KV namespace for items
//   ENVIRONMENT  dev, staging or prod
//   API_TOKEN    bearer token required on every data request

const KEY = /^[A-Za-z0-9._-]{1,128}$/;
const MAX_ITEM_BYTES = 64 * 1024;
const encoder = new TextEncoder();

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
      'x-content-type-options': 'nosniff',
    },
  });
}

async function digest(text) {
  return new Uint8Array(await crypto.subtle.digest('SHA-256', encoder.encode(text)));
}

/** Compares the bearer token with API_TOKEN without leaking where they differ. */
export async function authorised(request, env) {
  const header = request.headers.get('authorization') ?? '';
  if (!env.API_TOKEN || !header.startsWith('Bearer ')) {
    return false;
  }
  const [given, expected] = await Promise.all([
    digest(header.slice('Bearer '.length)),
    digest(env.API_TOKEN),
  ]);
  let difference = 0;
  for (let i = 0; i < expected.length; i += 1) {
    difference |= given[i] ^ expected[i];
  }
  return difference === 0;
}

// The table is created on first use, once per isolate, so the database needs
// no separate migration step.
const prepared = new WeakMap();

function itemStore(env) {
  if (env.DB) {
    const db = env.DB;
    if (!prepared.has(db)) {
      prepared.set(
        db,
        db
          .prepare(
            'CREATE TABLE IF NOT EXISTS items (key TEXT PRIMARY KEY, value TEXT NOT NULL, updated_at TEXT NOT NULL)',
          )
          .run(),
      );
    }
    const ready = prepared.get(db);
    return {
      async get(key) {
        await ready;
        const row = await db.prepare('SELECT value FROM items WHERE key = ?1').bind(key).first();
        return row ? row.value : null;
      },
      async put(key, value) {
        await ready;
        await db
          .prepare(
            'INSERT INTO items (key, value, updated_at) VALUES (?1, ?2, ?3) ' +
              'ON CONFLICT (key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at',
          )
          .bind(key, value, new Date().toISOString())
          .run();
      },
      async delete(key) {
        await ready;
        await db.prepare('DELETE FROM items WHERE key = ?1').bind(key).run();
      },
    };
  }
  if (env.KV) {
    return {
      get: key => env.KV.get(key),
      put: (key, value) => env.KV.put(key, value),
      delete: key => env.KV.delete(key),
    };
  }
  throw new Error('Neither a DB nor a KV binding is configured.');
}

async function handleItem(request, env, key) {
  const store = itemStore(env);
  switch (request.method) {
    case 'GET': {
      const value = await store.get(key);
      return value === null ? json({ error: 'Not found' }, 404) : json({ key, value });
    }
    case 'PUT': {
      const value = await request.text();
      if (encoder.encode(value).length > MAX_ITEM_BYTES) {
        return json({ error: 'The item is larger than 64 KiB; store it as a file instead' }, 413);
      }
      await store.put(key, value);
      return json({ key }, 201);
    }
    case 'DELETE':
      await store.delete(key);
      return new Response(null, { status: 204 });
    default:
      return json({ error: 'Method not allowed' }, 405);
  }
}

async function handleFile(request, env, key) {
  switch (request.method) {
    case 'GET': {
      const object = await env.BUCKET.get(key);
      if (object === null) {
        return json({ error: 'Not found' }, 404);
      }
      const headers = new Headers({ 'cache-control': 'no-store', 'x-content-type-options': 'nosniff' });
      object.writeHttpMetadata(headers);
      headers.set('etag', object.httpEtag);
      return new Response(object.body, { headers });
    }
    case 'PUT': {
      if (request.body === null) {
        return json({ error: 'The request has no body' }, 400);
      }
      await env.BUCKET.put(key, request.body, {
        httpMetadata: {
          contentType: request.headers.get('content-type') ?? 'application/octet-stream',
        },
      });
      return json({ key }, 201);
    }
    case 'DELETE':
      await env.BUCKET.delete(key);
      return new Response(null, { status: 204 });
    default:
      return json({ error: 'Method not allowed' }, 405);
  }
}

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);

    if (pathname === '/healthz') {
      return json({ status: 'ok', environment: env.ENVIRONMENT });
    }

    const match = /^\/(items|files)\/([^/]+)$/.exec(pathname);
    if (!match) {
      return json({ error: 'Not found' }, 404);
    }
    if (!(await authorised(request, env))) {
      return new Response(JSON.stringify({ error: 'Unauthorised' }), {
        status: 401,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'www-authenticate': 'Bearer',
        },
      });
    }

    const [, collection, key] = match;
    if (!KEY.test(key)) {
      return json({ error: 'Keys are 1 to 128 letters, digits, dots, underscores or hyphens' }, 400);
    }

    try {
      return collection === 'items'
        ? await handleItem(request, env, key)
        : await handleFile(request, env, key);
    } catch (error) {
      console.error(JSON.stringify({ message: 'Request failed', error: String(error), pathname }));
      return json({ error: 'Internal error' }, 500);
    }
  },
};
