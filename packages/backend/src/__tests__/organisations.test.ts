/**
 * Organisations API: runs every case in organisations/cases.json against the
 * real router on an in-memory SQLite database, or on Postgres when
 * ORGANISATIONS_TEST_POSTGRES holds a connection string (each case then gets
 * a schema of its own, dropped afterwards). The Cloudflare Worker runs the
 * same cases with its own runner, so the two backends answer alike.
 *
 * How a case is run (the Worker's runner follows the same rules):
 * - Each case gets a fresh random six-letter `run` id. In every string of a
 *   step's path, json, body and has, `{run}` becomes that id, `{jane}`,
 *   `{kim}` and `{sam}` become `user:default/jane-<run>` and so on, and
 *   `{admin}` becomes `user:default/organisations-check-admin`. Nothing is
 *   URL-encoded for the case: a path spells `%3A` and `%2F` itself.
 * - `as` names the caller: jane, kim or sam (those refs), `admin` (that
 *   ref, the one portal administrator, the same in every case), `guest`
 *   (`user:development/guest`), or null for no credentials.
 * - `json` is sent as a JSON body. `file` sends fixed bytes (FILES below) as
 *   the raw body with `contentType`.
 * - `query` is appended to the path after `?`. In it, `{v}` becomes the `v`
 *   of the last logo address (`logoFullUrl`, else `logoIconUrl`) an earlier
 *   response of the case contained.
 * - `status` must match. With `body`, the JSON response must equal it, where
 *   the string "<any>" stands for any value that is not null. With `has`,
 *   the list the JSON response holds under each key named must contain an
 *   item equal to each one given; it may hold others, as the list of every
 *   organisation does on a database that is not empty. With `headers`, each
 *   named response header must equal the value.
 */

import type { Server } from 'http';
import type { AddressInfo } from 'net';
import express from 'express';
import knexFactory, { Knex } from 'knex';
import type {
  HttpAuthService,
  LoggerService,
  UserInfoService,
} from '@backstage/backend-plugin-api';
import { provide } from '../accounts/directory';
import { initializeTables } from '../organisations/database';
import { createRouter } from '../organisations/routes';
import { GUEST_USER } from '../organisations/rules';
import cases from '../organisations/cases.json';

type Person = 'jane' | 'kim' | 'sam';

interface Step {
  as: Person | 'admin' | 'guest' | null;
  method: string;
  path: string;
  json?: unknown;
  file?: string;
  contentType?: string;
  query?: string;
  status: number;
  body?: unknown;
  has?: Record<string, unknown[]>;
  headers?: Record<string, string>;
}

const PEOPLE: Person[] = ['jane', 'kim', 'sam'];
/** The one portal administrator. */
const ADMIN = 'user:default/organisations-check-admin';
const CALLERS: Record<string, string> = { admin: ADMIN, guest: GUEST_USER };
const POSTGRES = process.env.ORGANISATIONS_TEST_POSTGRES;

const FILES: Record<string, Buffer> = {
  // A PNG of one pixel.
  png: Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    'base64',
  ),
  svg: Buffer.from(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>',
  ),
  text: Buffer.from('hello'),
};

const logger = {
  info: () => {},
  warn: () => {},
  error: () => {},
  debug: () => {},
  child: () => logger,
} as LoggerService;

// Only the calls the router makes; the rest of each service is not needed.
const httpAuth = {
  credentials: async (req: express.Request) => {
    const userEntityRef = req.header('x-test-user');
    if (!userEntityRef) {
      // What Backstage throws without a token, by name.
      const error = new Error('Missing credentials');
      error.name = 'AuthenticationError';
      throw error;
    }
    return { principal: { type: 'user', userEntityRef } };
  },
} as unknown as HttpAuthService;

const userInfo = {
  getUserInfo: async (credentials: {
    principal: { userEntityRef: string };
  }) => ({
    userEntityRef: credentials.principal.userEntityRef,
    ownershipEntityRefs: [credentials.principal.userEntityRef],
  }),
} as unknown as UserInfoService;

/** `value` with every placeholder in every string of it filled in. */
function fill<T>(value: T, run: string): T {
  if (typeof value === 'string') {
    let text = value.replaceAll('{run}', run).replaceAll('{admin}', ADMIN);
    for (const person of PEOPLE) {
      text = text.replaceAll(`{${person}}`, `user:default/${person}-${run}`);
    }
    return text as T;
  }
  if (Array.isArray(value)) {
    return value.map(item => fill(item, run)) as T;
  }
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, fill(item, run)]),
    ) as T;
  }
  return value;
}

/** The expectation as jest compares it: "<any>" is anything but null. */
function expected(value: unknown): unknown {
  if (value === '<any>') {
    return expect.anything();
  }
  if (Array.isArray(value)) {
    return value.map(expected);
  }
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, expected(item)]),
    );
  }
  return value;
}

/** A step's `has` as jest compares it: lists that hold each item given. */
const holding = (has: Record<string, unknown[]>) =>
  Object.fromEntries(
    Object.entries(has).map(([key, items]) => [
      key,
      expect.arrayContaining(items.map(expected)),
    ]),
  );

describe('organisations API', () => {
  let knex: Knex;
  let server: Server;
  let baseUrl: string;
  /** The Postgres schema the case's tables are in. */
  let schema: string;
  /** What the router asked the catalog to file under another account. */
  let moved: Array<{ from: string; to: string }>;

  beforeAll(() => {
    // What the branding plugin and the catalog answer in the backend.
    provide({
      isPortalAdmin: async userRef => userRef === ADMIN,
      portalAdmins: async () => [ADMIN],
    });
    provide({
      moveAccount: async (from, to) => {
        moved.push({ from, to });
      },
    });
  });

  beforeEach(async () => {
    moved = [];
    if (POSTGRES) {
      schema = `organisations_test_${Date.now()}_${Math.floor(
        Math.random() * 1e6,
      )}`;
      knex = knexFactory({
        client: 'pg',
        connection: POSTGRES,
        searchPath: [schema],
      });
      await knex.raw('CREATE SCHEMA ??', [schema]);
    } else {
      knex = knexFactory({
        client: 'better-sqlite3',
        connection: ':memory:',
        useNullAsDefault: true,
        pool: {
          // SQLite keeps to the references between tables only on a
          // connection that asks for it.
          afterCreate: (
            connection: { pragma: (text: string) => unknown },
            done: (error: Error | null, connection: unknown) => void,
          ) => {
            connection.pragma('foreign_keys = ON');
            done(null, connection);
          },
        },
      });
    }
    await initializeTables(knex, logger);
    const app = express();
    app.use(createRouter({ knex, logger, httpAuth, userInfo }));
    // The framework's part: whatever the router does not answer itself.
    app.use(
      (
        error: Error,
        _req: express.Request,
        res: express.Response,
        _next: express.NextFunction,
      ) => {
        res
          .status(error.name === 'AuthenticationError' ? 401 : 500)
          .json({ error: { name: error.name, message: error.message } });
      },
    );
    server = app.listen(0);
    await new Promise(resolve => server.once('listening', resolve));
    baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  });

  afterEach(async () => {
    await new Promise(resolve => server.close(resolve));
    if (POSTGRES) {
      await knex.raw('DROP SCHEMA ?? CASCADE', [schema]);
    }
    await knex.destroy();
  });

  /** One call to the API as `user`, with a JSON body when one is given. */
  const call = (user: string, method: string, path: string, json?: unknown) =>
    fetch(`${baseUrl}${path}`, {
      method,
      headers: { 'x-test-user': user, 'content-type': 'application/json' },
      body: json === undefined ? undefined : JSON.stringify(json),
    });

  it('passes what a deleted organisation registered on to its longest-standing owner', async () => {
    const [jane, kim] = ['user:default/jane', 'user:default/kim'];
    await call(kim, 'POST', '/', { name: 'Acme', slug: 'acme' });
    await call(kim, 'POST', '/acme/members', {
      entityRef: jane,
      role: 'owner',
    });
    await call(jane, 'POST', '/acme/join');
    // Renamed and moved: what it registered is filed under its id, which
    // stays.
    const { id } = await knex('organisations').first('id');
    await call(jane, 'PATCH', '/acme', { name: 'Acme Two', slug: 'acme-two' });
    expect(moved).toEqual([]);

    // Deleted by the newer owner; the older one, though later in the
    // alphabet, takes over.
    const response = await call(jane, 'DELETE', '/acme-two');

    expect(response.status).toBe(204);
    expect(id).toMatch(/^[0-9a-f]{32}$/);
    expect(moved).toEqual([{ from: `organisation:${id}`, to: kim }]);
  });

  it('gives organisations from before names were unique an id and a name key', async () => {
    // The tables as they were first made, with two organisations that
    // share a name.
    for (const table of [
      'organisation_logos',
      'organisation_invitations',
      'organisation_members',
      'organisations',
    ]) {
      await knex.schema.dropTable(table);
    }
    await knex.schema.createTable('organisations', table => {
      table.string('slug').primary();
      table.string('name').notNullable();
      table.string('primary_color').nullable();
      table.string('theme_preset').nullable();
    });
    await knex.schema.createTable('organisation_members', table => {
      table.string('user_ref').primary();
      table.string('slug').notNullable();
      table.string('role').notNullable();
      table.string('added_at').notNullable();
      table.string('added_by').notNullable();
    });
    await knex('organisations').insert([
      { slug: 'acme', name: 'Acme  Ltd' },
      { slug: 'first', name: 'ACME Ltd' },
      { slug: 'other', name: 'Other' },
    ]);
    await knex('organisation_members').insert(
      [
        ['user:default/a', 'acme', '2026-02-01T00:00:00.000Z'],
        ['user:default/b', 'first', '2026-01-01T00:00:00.000Z'],
        ['user:default/c', 'other', '2026-03-01T00:00:00.000Z'],
      ].map(([user_ref, slug, added_at]) => ({
        user_ref,
        slug,
        role: 'owner',
        added_at,
        added_by: user_ref,
      })),
    );

    await initializeTables(knex, logger);
    // A second start changes nothing.
    await initializeTables(knex, logger);

    const rows = await knex('organisations')
      .orderBy('slug')
      .select('slug', 'name', 'id', 'name_key');
    expect(rows).toEqual([
      {
        slug: 'acme',
        name: 'Acme  Ltd',
        id: expect.stringMatching(/^[0-9a-f]{32}$/),
        name_key: 'acme ltd (acme)',
      },
      {
        slug: 'first',
        name: 'ACME Ltd',
        id: expect.stringMatching(/^[0-9a-f]{32}$/),
        name_key: 'acme ltd',
      },
      {
        slug: 'other',
        name: 'Other',
        id: expect.stringMatching(/^[0-9a-f]{32}$/),
        name_key: 'other',
      },
    ]);
    expect(new Set(rows.map(row => row.id)).size).toBe(3);
    // The name the first one holds is taken; the later one can be renamed.
    const taken = await call('user:default/a', 'PATCH', '/acme', {
      name: 'acme ltd',
    });
    expect(taken.status).toBe(409);
    const renamed = await call('user:default/a', 'PATCH', '/acme', {
      name: 'Acme Two',
    });
    expect(renamed.status).toBe(200);
  });

  it.each(cases as Array<{ name: string; steps: Step[] }>)(
    '$name',
    async ({ steps }) => {
      const run = Array.from({ length: 6 }, () =>
        String.fromCharCode(97 + Math.floor(Math.random() * 26)),
      ).join('');
      let version = '';

      for (const [index, step] of steps.entries()) {
        const user =
          step.as && (CALLERS[step.as] ?? `user:default/${step.as}-${run}`);
        const headers: Record<string, string> = {};
        let body: string | Buffer | undefined;
        if (user) {
          headers['x-test-user'] = user;
        }
        if (step.file) {
          body = FILES[step.file];
          headers['content-type'] = step.contentType ?? '';
        } else if (step.json !== undefined) {
          body = JSON.stringify(fill(step.json, run));
          headers['content-type'] = 'application/json';
        }
        const query = step.query?.replaceAll('{v}', version);
        const address = `${fill(step.path, run)}${query ? `?${query}` : ''}`;

        const response = await fetch(`${baseUrl}${address}`, {
          method: step.method,
          headers,
          body,
        });
        const text = await response.text();
        const where = `step ${index + 1}: ${step.method} ${address} as ${
          step.as
        }`;

        // What the step asks for, beside what came back.
        const wanted: Record<string, unknown> = { where, status: step.status };
        const seen: Record<string, unknown> = {
          where,
          status: response.status,
        };
        if (step.body !== undefined) {
          wanted.body = expected(fill(step.body, run));
          seen.body = JSON.parse(text);
        }
        for (const [name, value] of Object.entries(step.headers ?? {})) {
          wanted[name] = value;
          seen[name] = response.headers.get(name);
        }
        if (step.has) {
          const answer = JSON.parse(text);
          wanted.has = holding(fill(step.has, run));
          seen.has = Object.fromEntries(
            Object.keys(step.has).map(key => [key, answer?.[key]]),
          );
        }
        expect(seen).toEqual(wanted);

        if (response.headers.get('content-type')?.includes('json') && text) {
          const answer = JSON.parse(text);
          const logo = answer?.logoFullUrl ?? answer?.logoIconUrl;
          if (typeof logo === 'string') {
            version = new URLSearchParams(logo.split('?')[1]).get('v') ?? '';
          }
        }
      }
    },
  );
});
