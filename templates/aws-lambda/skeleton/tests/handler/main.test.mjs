// Unit tests for the Node.js handler in src/main.mjs.
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { handler } from '../../src/main.mjs';

test('handler returns a greeting', async () => {
  process.env.ENVIRONMENT = 'test';

  const response = await handler({});

  assert.equal(response.statusCode, 200);
  assert.deepEqual(JSON.parse(response.body), {
    message: 'Hello from ${{ values.name }}',
    environment: 'test',
  });
});

test('handler falls back to an unknown environment', async () => {
  delete process.env.ENVIRONMENT;

  const body = JSON.parse((await handler({})).body);

  assert.equal(body.environment, 'unknown');
});
