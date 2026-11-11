// Tests of the Worker with in-memory bindings:  node --test "worker/*.test.mjs"
import assert from 'node:assert/strict';
import { test } from 'node:test';
import worker from './index.mjs';

const TOKEN = 'test-token';

function fakeKv() {
  const data = new Map();
  return {
    get: async key => data.get(key) ?? null,
    put: async (key, value) => void data.set(key, value),
    delete: async key => void data.delete(key),
  };
}

function fakeBucket() {
  const data = new Map();
  return {
    async get(key) {
      const object = data.get(key);
      if (!object) {
        return null;
      }
      return {
        body: object.bytes,
        httpEtag: '"etag"',
        writeHttpMetadata: headers => headers.set('content-type', object.contentType),
      };
    },
    async put(key, body, options) {
      const bytes = new Uint8Array(await new Response(body).arrayBuffer());
      data.set(key, { bytes, contentType: options.httpMetadata.contentType });
    },
    delete: async key => void data.delete(key),
  };
}

/** Understands exactly the statements the Worker sends to D1. */
function fakeD1() {
  const rows = new Map();
  const statements = [];
  const statement = (sql, values = []) => ({
    bind: (...bound) => statement(sql, bound),
    async run() {
      statements.push(sql);
      if (sql.startsWith('INSERT')) {
        rows.set(values[0], values[1]);
      } else if (sql.startsWith('DELETE')) {
        rows.delete(values[0]);
      }
    },
    async first() {
      return rows.has(values[0]) ? { value: rows.get(values[0]) } : null;
    },
  });
  return { prepare: sql => statement(sql), statements };
}

function call(env, method, path, { body, token = TOKEN, headers = {} } = {}) {
  const request = new Request(`https://worker.test${path}`, {
    method,
    body,
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), ...headers },
  });
  return worker.fetch(request, env);
}

const kvEnv = () => ({ KV: fakeKv(), BUCKET: fakeBucket(), API_TOKEN: TOKEN, ENVIRONMENT: 'dev' });

test('the health check needs no token', async () => {
  const response = await call(kvEnv(), 'GET', '/healthz', { token: null });
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok', environment: 'dev' });
});

test('data requests without a valid token are refused', async () => {
  const env = kvEnv();
  assert.equal((await call(env, 'GET', '/items/a', { token: null })).status, 401);
  assert.equal((await call(env, 'GET', '/items/a', { token: 'wrong' })).status, 401);
  assert.equal((await call(env, 'PUT', '/files/a', { token: 'wrong', body: 'x' })).status, 401);
});

test('a Worker without API_TOKEN refuses every data request', async () => {
  const env = { ...kvEnv(), API_TOKEN: undefined };
  assert.equal((await call(env, 'GET', '/items/a', { token: 'undefined' })).status, 401);
});

test('items are stored in KV', async () => {
  const env = kvEnv();
  assert.equal((await call(env, 'GET', '/items/greeting')).status, 404);
  assert.equal((await call(env, 'PUT', '/items/greeting', { body: 'hello' })).status, 201);
  assert.deepEqual(await (await call(env, 'GET', '/items/greeting')).json(), {
    key: 'greeting',
    value: 'hello',
  });
  assert.equal((await call(env, 'DELETE', '/items/greeting')).status, 204);
  assert.equal((await call(env, 'GET', '/items/greeting')).status, 404);
});

test('items are stored in D1 and the table is created once', async () => {
  const env = { DB: fakeD1(), BUCKET: fakeBucket(), API_TOKEN: TOKEN, ENVIRONMENT: 'dev' };
  assert.equal((await call(env, 'PUT', '/items/a', { body: 'one' })).status, 201);
  assert.equal((await call(env, 'PUT', '/items/a', { body: 'two' })).status, 201);
  assert.equal((await (await call(env, 'GET', '/items/a')).json()).value, 'two');
  assert.equal(env.DB.statements.filter(sql => sql.startsWith('CREATE TABLE')).length, 1);
});

test('oversized items and invalid keys are rejected', async () => {
  const env = kvEnv();
  const large = 'x'.repeat(64 * 1024 + 1);
  assert.equal((await call(env, 'PUT', '/items/large', { body: large })).status, 413);
  assert.equal((await call(env, 'GET', '/items/not%20valid')).status, 400);
  assert.equal((await call(env, 'POST', '/items/a', { body: 'x' })).status, 405);
});

test('files round-trip through R2 with their content type', async () => {
  const env = kvEnv();
  const put = await call(env, 'PUT', '/files/report.csv', {
    body: 'a,b\n1,2\n',
    headers: { 'content-type': 'text/csv' },
  });
  assert.equal(put.status, 201);
  const get = await call(env, 'GET', '/files/report.csv');
  assert.equal(get.status, 200);
  assert.equal(get.headers.get('content-type'), 'text/csv');
  assert.equal(await get.text(), 'a,b\n1,2\n');
  assert.equal((await call(env, 'DELETE', '/files/report.csv')).status, 204);
  assert.equal((await call(env, 'GET', '/files/report.csv')).status, 404);
});

test('unknown paths are not found', async () => {
  assert.equal((await call(kvEnv(), 'GET', '/')).status, 404);
});
