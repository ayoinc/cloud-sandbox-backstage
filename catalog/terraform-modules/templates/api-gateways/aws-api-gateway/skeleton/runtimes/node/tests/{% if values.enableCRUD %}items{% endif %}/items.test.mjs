import assert from 'node:assert/strict';
import { beforeEach, test } from 'node:test';
import { itemRoutes } from '../../src/items/items.mjs';
import { route } from '../../src/router.mjs';

// The store interface of src/items/store.mjs, kept in memory.
function createMemoryStore() {
  const items = new Map();
  return {
    list: async () => [...items.values()],
    get: async id => items.get(id) ?? null,
    put: async item => void items.set(item.id, item),
    delete: async id => items.delete(id),
  };
}

let routes;

const call = (httpMethod, resource, { id, body } = {}) =>
  route(routes, {
    httpMethod,
    resource,
    pathParameters: id ? { id } : null,
    body: body === undefined ? null : JSON.stringify(body),
    isBase64Encoded: false,
  });

const create = async attributes =>
  JSON.parse((await call('POST', '/items', { body: attributes })).body);

beforeEach(() => {
  routes = itemRoutes(createMemoryStore());
});

test('POST /items stores the body with an id and timestamps', async () => {
  const response = await call('POST', '/items', { body: { name: 'first' } });
  assert.equal(response.statusCode, 201);
  const item = JSON.parse(response.body);
  assert.equal(item.name, 'first');
  assert.match(item.id, /^[0-9a-f-]{36}$/);
  assert.equal(item.createdAt, item.updatedAt);
  assert.ok(!Number.isNaN(Date.parse(item.createdAt)));
});

test('POST /items rejects a body that is not a JSON object', async () => {
  const response = await call('POST', '/items', { body: ['not', 'an', 'object'] });
  assert.equal(response.statusCode, 400);
  assert.deepEqual(JSON.parse(response.body), {
    message: 'The request body must be a JSON object',
  });
});

test('GET /items lists what was stored', async () => {
  const first = await create({ name: 'first' });
  const second = await create({ name: 'second' });
  const response = await call('GET', '/items');
  assert.equal(response.statusCode, 200);
  assert.deepEqual(JSON.parse(response.body), { items: [first, second] });
});

test('GET /items/{id} returns the item or 404', async () => {
  const item = await create({ name: 'first' });
  const found = await call('GET', '/items/{id}', { id: item.id });
  assert.equal(found.statusCode, 200);
  assert.deepEqual(JSON.parse(found.body), item);

  const missing = await call('GET', '/items/{id}', { id: 'unknown' });
  assert.equal(missing.statusCode, 404);
  assert.deepEqual(JSON.parse(missing.body), { message: 'Item not found' });
});

test('PUT /items/{id} replaces the attributes and keeps id and createdAt', async () => {
  const item = await create({ name: 'first', colour: 'red' });
  const response = await call('PUT', '/items/{id}', {
    id: item.id,
    body: { name: 'renamed', id: 'ignored', createdAt: 'ignored' },
  });
  assert.equal(response.statusCode, 200);
  const updated = JSON.parse(response.body);
  assert.equal(updated.name, 'renamed');
  assert.equal(updated.colour, undefined);
  assert.equal(updated.id, item.id);
  assert.equal(updated.createdAt, item.createdAt);

  const stored = await call('GET', '/items/{id}', { id: item.id });
  assert.deepEqual(JSON.parse(stored.body), updated);
});

test('PUT /items/{id} answers 404 for an unknown id and 400 for a bad body', async () => {
  const missing = await call('PUT', '/items/{id}', { id: 'unknown', body: {} });
  assert.equal(missing.statusCode, 404);

  const item = await create({ name: 'first' });
  const invalid = await call('PUT', '/items/{id}', { id: item.id, body: 'text' });
  assert.equal(invalid.statusCode, 400);
});

test('DELETE /items/{id} removes the item, then answers 404', async () => {
  const item = await create({ name: 'first' });
  const deleted = await call('DELETE', '/items/{id}', { id: item.id });
  assert.equal(deleted.statusCode, 204);
  assert.equal(deleted.body, '');

  const again = await call('DELETE', '/items/{id}', { id: item.id });
  assert.equal(again.statusCode, 404);
});
