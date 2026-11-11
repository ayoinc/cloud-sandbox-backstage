const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const { SERVICE, createServer } = require('../src/server');

const server = createServer();
let baseUrl;

before(async () => {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(() => new Promise((resolve) => server.close(resolve)));

test('GET / returns the service name and environment', async () => {
  const response = await fetch(`${baseUrl}/`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    service: SERVICE,
    environment: process.env.ENVIRONMENT ?? 'local',
  });
});

test('GET /health reports healthy', async () => {
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'healthy' });
});

test('GET /ready reports ready', async () => {
  const response = await fetch(`${baseUrl}/ready`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ready' });
});

test('GET /metrics counts requests in the Prometheus text format', async () => {
  const response = await fetch(`${baseUrl}/metrics`);
  assert.equal(response.status, 200);
  assert.match(await response.text(), /^http_requests_total \d+$/m);
});

test('unknown paths return 404', async () => {
  const response = await fetch(`${baseUrl}/missing`);
  assert.equal(response.status, 404);
});
