import http from 'node:http';
import type { AddressInfo } from 'node:net';
import { exportJWK, generateKeyPair, SignJWT } from 'jose';
import { afterEach, describe, expect, it } from 'vitest';
import { CREATE_PRODUCT, JWT_SECRET, signToken, startTestServer, type TestServer } from './helpers.js';

const input = { name: 'Widget', priceCents: 100 };
const VIEWER = '{ viewer { id roles } }';

let server: TestServer | undefined;
afterEach(async () => {
  await server?.close();
  server = undefined;
});

describe('authentication with the jwt provider', () => {
  const auth = { enabled: true, provider: 'jwt' as const, jwtSecret: JWT_SECRET };

  it('lets anonymous callers read but not write', async () => {
    server = await startTestServer({ auth });

    expect((await server.query('{ products { id } }')).body).toEqual({ data: { products: [] } });
    expect((await server.query(VIEWER)).body).toEqual({ data: { viewer: null } });

    const write = await server.query(CREATE_PRODUCT, { variables: { input } });
    expect(write.body.errors![0]!.extensions!.code).toBe('UNAUTHENTICATED');
  });

  it('identifies the caller from a valid token and lets them write', async () => {
    server = await startTestServer({ auth });
    const token = await signToken(['editor'], 'user-42');

    expect((await server.query(VIEWER, { token })).body).toEqual({
      data: { viewer: { id: 'user-42', roles: ['editor'] } },
    });
    const write = await server.query(CREATE_PRODUCT, { variables: { input }, token });
    expect(write.body.data!.createProduct.name).toBe('Widget');
  });

  it('rejects a token with a bad signature', async () => {
    server = await startTestServer({ auth });
    const forged = await new SignJWT({ roles: ['admin'] })
      .setProtectedHeader({ alg: 'HS256' })
      .setSubject('intruder')
      .sign(new TextEncoder().encode('another-secret-that-is-also-long-enough'));

    const result = await server.query(VIEWER, { token: forged });

    expect(result.status).toBe(401);
    expect(result.body.errors![0]!.extensions!.code).toBe('UNAUTHENTICATED');
  });

  it('with role-based access control, only admins write', async () => {
    server = await startTestServer({ auth: { ...auth, rbac: true } });

    const asEditor = await server.query(CREATE_PRODUCT, { variables: { input }, token: await signToken(['editor']) });
    expect(asEditor.body.errors![0]!.extensions!.code).toBe('FORBIDDEN');

    const asAdmin = await server.query(CREATE_PRODUCT, { variables: { input }, token: await signToken(['admin']) });
    expect(asAdmin.body.errors).toBeUndefined();
  });

  it('with authentication off, everyone writes', async () => {
    server = await startTestServer({ auth: { enabled: false } });

    const write = await server.query(CREATE_PRODUCT, { variables: { input } });
    expect(write.body.errors).toBeUndefined();
  });
});

describe('authentication with the oauth2 provider', () => {
  it('checks tokens against the keys, issuer and audience of the identity provider', async () => {
    // A stand-in identity provider: it publishes its public key as a JWKS.
    const { publicKey, privateKey } = await generateKeyPair('RS256');
    const jwks = { keys: [{ ...(await exportJWK(publicKey)), kid: 'key-1', alg: 'RS256', use: 'sig' }] };
    const provider = http.createServer((_req, res) => {
      res.setHeader('content-type', 'application/json').end(JSON.stringify(jwks));
    });
    await new Promise<void>(resolve => provider.listen(0, '127.0.0.1', resolve));
    const issuer = `http://127.0.0.1:${(provider.address() as AddressInfo).port}/`;

    const sign = (audience: string) =>
      new SignJWT({ roles: ['admin'] })
        .setProtectedHeader({ alg: 'RS256', kid: 'key-1' })
        .setSubject('oauth-user')
        .setIssuer(issuer)
        .setAudience(audience)
        .setExpirationTime('5m')
        .sign(privateKey);

    try {
      server = await startTestServer({
        auth: {
          enabled: true,
          provider: 'oauth2',
          rbac: true,
          issuer,
          audience: 'sample-api',
          jwksUri: `${issuer}.well-known/jwks.json`,
        },
      });

      const accepted = await server.query(VIEWER, { token: await sign('sample-api') });
      expect(accepted.body).toEqual({ data: { viewer: { id: 'oauth-user', roles: ['admin'] } } });

      const wrongAudience = await server.query(VIEWER, { token: await sign('another-api') });
      expect(wrongAudience.body.errors![0]!.extensions!.code).toBe('UNAUTHENTICATED');
    } finally {
      await new Promise(resolve => provider.close(resolve));
    }
  });
});
