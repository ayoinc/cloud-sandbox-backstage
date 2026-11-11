import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  HttpError,
  json,
  notImplemented,
  parseObject,
  route,
} from '../src/router.mjs';

const event = (httpMethod, resource, extra = {}) => ({
  httpMethod,
  resource,
  pathParameters: null,
  body: null,
  isBase64Encoded: false,
  ...extra,
});

test('calls the handler registered for the method and resource', async () => {
  const routes = { 'GET /things': () => json(200, { ok: true }) };
  const response = await route(routes, event('GET', '/things'));
  assert.equal(response.statusCode, 200);
  assert.equal(response.headers['Content-Type'], 'application/json');
  assert.deepEqual(JSON.parse(response.body), { ok: true });
});

test('answers 404 for a route that is not registered', async () => {
  const response = await route({}, event('GET', '/missing'));
  assert.equal(response.statusCode, 404);
  assert.deepEqual(JSON.parse(response.body), { message: 'Not found' });
});

test('turns an HttpError into its status and message', async () => {
  const routes = {
    'GET /things': () => {
      throw new HttpError(409, 'Conflict');
    },
  };
  const response = await route(routes, event('GET', '/things'));
  assert.equal(response.statusCode, 409);
  assert.deepEqual(JSON.parse(response.body), { message: 'Conflict' });
});

test('answers 500 when a handler fails unexpectedly', async t => {
  t.mock.method(console, 'error', () => {});
  const routes = {
    'GET /things': () => {
      throw new Error('boom');
    },
  };
  const response = await route(routes, event('GET', '/things'));
  assert.equal(response.statusCode, 500);
  assert.deepEqual(JSON.parse(response.body), {
    message: 'Internal server error',
  });
});

test('a stubbed endpoint answers 501 with its method and path', async () => {
  const routes = { 'POST /reports/{id}': notImplemented };
  const response = await route(routes, event('POST', '/reports/{id}'));
  assert.equal(response.statusCode, 501);
  assert.deepEqual(JSON.parse(response.body), {
    message: 'POST /reports/{id} is not implemented',
  });
});

test('parseObject reads plain and base64 bodies', () => {
  assert.deepEqual(parseObject(event('POST', '/x', { body: '{"a":1}' })), {
    a: 1,
  });
  const encoded = Buffer.from('{"b":2}').toString('base64');
  assert.deepEqual(
    parseObject(event('POST', '/x', { body: encoded, isBase64Encoded: true })),
    { b: 2 },
  );
});

test('parseObject rejects anything that is not a JSON object', () => {
  for (const body of [null, '', 'not json', '[1]', '"text"', '3', 'null']) {
    assert.throws(
      () => parseObject(event('POST', '/x', { body })),
      error => error instanceof HttpError && error.statusCode === 400,
    );
  }
});
