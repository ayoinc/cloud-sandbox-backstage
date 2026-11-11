import type { AddressInfo } from 'node:net';
import { SignJWT } from 'jose';
import type { Knex } from 'knex';
import { type Config, loadConfig } from '../src/config.js';
import { createDb, migrate } from '../src/db/index.js';
import { createServer, type ServerDependencies } from '../src/server.js';

export const JWT_SECRET = 'test-secret-that-is-long-enough-for-hs256';

type Overrides = Partial<Omit<Config, 'auth' | 'cache'>> & {
  auth?: Partial<Config['auth']>;
  cache?: Partial<Config['cache']>;
};

/** The database the tests use: SQLite in memory, or the server DATABASE_URL points at. */
function testDatabase(): Config['database'] {
  const { database } = loadConfig({ DATABASE_URL: process.env.DATABASE_URL, AUTH_ENABLED: 'false' });
  return database.client === 'better-sqlite3' ? { ...database, url: ':memory:' } : database;
}

/** A configuration with every optional feature off, plus the given overrides. */
export function testConfig(overrides: Overrides = {}): Config {
  return {
    nodeEnv: 'test',
    port: 0,
    database: testDatabase(),
    subscriptions: false,
    playground: false,
    queryComplexityLimit: 1000,
    metrics: false,
    tracing: { enabled: false },
    ...overrides,
    cache: { enabled: false, ttlSeconds: 30, ...overrides.cache },
    auth: { enabled: false, provider: 'jwt', rbac: false, rolesClaim: 'roles', ...overrides.auth },
  };
}

/** Opens the test database with an up-to-date, empty schema. */
export async function createTestDb(): Promise<Knex> {
  const db = createDb(testDatabase());
  await migrate(db);
  await db('products').delete();
  return db;
}

// Each test asserts the shape of the data it asked for, so results are not typed further.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Loose = Record<string, any>;

export interface GraphQLResult {
  status: number;
  headers: Headers;
  body: { data?: Loose | null; errors?: { message: string; extensions?: Loose }[] };
}

export interface TestServer {
  url: string;
  db: Knex;
  query(query: string, options?: { variables?: Record<string, unknown>; token?: string }): Promise<GraphQLResult>;
  close(): Promise<void>;
}

/** Starts the API on a free port against an empty test database. */
export async function startTestServer(
  overrides: Overrides = {},
  dependencies: Omit<ServerDependencies, 'db'> = {},
): Promise<TestServer> {
  const db = await createTestDb();
  const server = await createServer(testConfig(overrides), { db, ...dependencies });
  await new Promise<void>(resolve => server.httpServer.listen(0, '127.0.0.1', resolve));
  const { port } = server.httpServer.address() as AddressInfo;
  const url = `http://127.0.0.1:${port}`;

  return {
    url,
    db,
    async query(query, { variables, token } = {}) {
      const response = await fetch(`${url}/graphql`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}) },
        body: JSON.stringify({ query, variables }),
      });
      return { status: response.status, headers: response.headers, body: await response.json() };
    },
    async close() {
      await server.stop();
      await db.destroy();
    },
  };
}

/** Signs an HS256 token the way the jwt provider expects it. */
export function signToken(roles: string[], subject = 'user-1'): Promise<string> {
  return new SignJWT({ roles })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(subject)
    .setExpirationTime('5m')
    .sign(new TextEncoder().encode(JWT_SECRET));
}

export const CREATE_PRODUCT = /* GraphQL */ `
  mutation CreateProduct($input: CreateProductInput!) {
    createProduct(input: $input) {
      id
      name
      description
      priceCents
      inStock
      createdAt
    }
  }
`;
