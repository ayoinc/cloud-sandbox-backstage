import assert from 'node:assert/strict';
import { test } from 'node:test';
import { handler } from '../src/index.mjs';
import { notImplemented } from '../src/router.mjs';
import { routes } from '../src/routes.mjs';

test('every route key is "<METHOD> <path>"', () => {
  for (const key of Object.keys(routes)) {
    assert.match(key, /^(GET|POST|PUT|DELETE) \/\S*$/);
    assert.equal(typeof routes[key], 'function');
  }
});

test('GET /health reports the service', async () => {
  const response = await handler({ httpMethod: 'GET', resource: '/health' });
  assert.equal(response.statusCode, 200);
  const body = JSON.parse(response.body);
  assert.equal(body.status, 'ok');
  assert.ok(body.service);
  assert.ok(body.version);
});

test('endpoints without an implementation answer 501', async () => {
  const stubbed = Object.keys(routes).filter(
    key => routes[key] === notImplemented,
  );
  for (const key of stubbed) {
    const [httpMethod, resource] = key.split(' ');
    const response = await handler({ httpMethod, resource });
    assert.equal(response.statusCode, 501);
    assert.deepEqual(JSON.parse(response.body), {
      message: `${key} is not implemented`,
    });
  }
});
