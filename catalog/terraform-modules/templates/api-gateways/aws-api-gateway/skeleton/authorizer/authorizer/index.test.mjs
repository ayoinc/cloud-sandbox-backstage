import assert from 'node:assert/strict';
import { generateKeyPairSync, sign } from 'node:crypto';
import { test } from 'node:test';
import {
  allowPolicy,
  createHandler,
  createKeySource,
  verifyToken,
} from './index.mjs';

const ISSUER = 'https://issuer.example.com/';
const AUDIENCE = 'orders-api';
const NOW = Date.parse('2030-01-01T00:00:00Z');
const NOW_SECONDS = NOW / 1000;

const rsa = generateKeyPairSync('rsa', { modulusLength: 2048 });
const ec = generateKeyPairSync('ec', { namedCurve: 'P-256' });
const jwks = {
  keys: [
    { ...rsa.publicKey.export({ format: 'jwk' }), kid: 'rsa-1', alg: 'RS256' },
    { ...ec.publicKey.export({ format: 'jwk' }), kid: 'ec-1', alg: 'ES256' },
  ],
};

const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');

function token(claims = {}, { kid = 'rsa-1', alg = 'RS256', key = rsa.privateKey } = {}) {
  const input = `${encode({ alg, kid, typ: 'JWT' })}.${encode({
    iss: ISSUER,
    aud: AUDIENCE,
    sub: 'user-1',
    exp: NOW_SECONDS + 600,
    ...claims,
  })}`;
  const signature = sign('sha256', Buffer.from(input), {
    key,
    dsaEncoding: alg.startsWith('ES') ? 'ieee-p1363' : undefined,
  });
  return `${input}.${signature.toString('base64url')}`;
}

const getKey = async kid => jwks.keys.find(key => key.kid === kid);
const options = { issuer: ISSUER, audience: AUDIENCE, getKey, now: NOW };

test('accepts a valid RSA-signed token', async () => {
  const claims = await verifyToken(token(), options);
  assert.equal(claims.sub, 'user-1');
});

test('accepts a valid EC-signed token', async () => {
  const claims = await verifyToken(
    token({}, { kid: 'ec-1', alg: 'ES256', key: ec.privateKey }),
    options,
  );
  assert.equal(claims.sub, 'user-1');
});

test('accepts an audience list and an issuer without the trailing slash', async () => {
  const claims = await verifyToken(
    token({ aud: ['other', AUDIENCE], iss: 'https://issuer.example.com' }),
    options,
  );
  assert.equal(claims.sub, 'user-1');
});

test('rejects a wrong issuer, audience or validity period', async () => {
  const cases = {
    'Wrong issuer': { iss: 'https://attacker.example.com/' },
    'Wrong audience': { aud: 'another-api' },
    'Token expired': { exp: NOW_SECONDS - 3600 },
    'Token not valid yet': { nbf: NOW_SECONDS + 3600 },
  };
  for (const [message, claims] of Object.entries(cases)) {
    await assert.rejects(verifyToken(token(claims), options), { message });
  }
});

test('rejects a token signed with another key', async () => {
  const other = generateKeyPairSync('rsa', { modulusLength: 2048 });
  await assert.rejects(
    verifyToken(token({}, { key: other.privateKey }), options),
    { message: 'Invalid signature' },
  );
});

test('rejects unknown keys, unsigned tokens and garbage', async () => {
  await assert.rejects(verifyToken(token({}, { kid: 'missing' }), options), {
    message: 'Unknown signing key missing',
  });
  const unsigned = `${encode({ alg: 'none' })}.${encode({ iss: ISSUER })}.`;
  await assert.rejects(verifyToken(unsigned, options), {
    message: 'Unsupported algorithm none',
  });
  await assert.rejects(verifyToken('not-a-token', options), {
    message: 'Not a JWT',
  });
});

test('the key source caches the key set and limits refetches for unknown key ids', async () => {
  let calls = 0;
  let time = NOW;
  const fetchImpl = async () => {
    calls += 1;
    return { ok: true, json: async () => jwks };
  };
  const source = createKeySource(
    'https://issuer.example.com/jwks',
    fetchImpl,
    () => time,
  );
  assert.equal((await source('rsa-1')).kid, 'rsa-1');
  assert.equal((await source('ec-1')).kid, 'ec-1');
  assert.equal(await source('rotated'), undefined);
  assert.equal(calls, 1);

  time += 61 * 1000;
  assert.equal(await source('rotated'), undefined);
  assert.equal(calls, 2);

  time += 11 * 60 * 1000;
  assert.equal((await source('rsa-1')).kid, 'rsa-1');
  assert.equal(calls, 3);
});

test('the key source fails when the key set cannot be read', async () => {
  const source = createKeySource('https://issuer.example.com/jwks', async () => ({
    ok: false,
    status: 503,
  }));
  await assert.rejects(source('rsa-1'), { message: 'The key set answered 503' });
});

test('the policy allows every method of the stage', () => {
  const policy = allowPolicy(
    'user-1',
    'arn:aws:execute-api:eu-west-1:123456789012:abc123/v1/GET/items/42',
    { sub: 'user-1', scope: 'read' },
  );
  assert.equal(policy.principalId, 'user-1');
  assert.equal(
    policy.policyDocument.Statement[0].Resource,
    'arn:aws:execute-api:eu-west-1:123456789012:abc123/v1/*/*',
  );
  assert.deepEqual(policy.context, { sub: 'user-1', scope: 'read' });
});

test('the handler returns a policy for a valid token and Unauthorized otherwise', async t => {
  t.mock.method(console, 'warn', () => {});
  const handler = createHandler({
    issuer: ISSUER,
    audience: AUDIENCE,
    getKey,
  });
  const methodArn = 'arn:aws:execute-api:eu-west-1:123456789012:abc123/v1/GET/items';
  const valid = token({ exp: Math.floor(Date.now() / 1000) + 600 });

  const policy = await handler({ authorizationToken: `Bearer ${valid}`, methodArn });
  assert.equal(policy.policyDocument.Statement[0].Effect, 'Allow');

  await assert.rejects(
    handler({ authorizationToken: 'Bearer invalid', methodArn }),
    { message: 'Unauthorized' },
  );
  await assert.rejects(handler({ methodArn }), { message: 'Unauthorized' });
});
