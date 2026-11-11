/**
 * Accounts of registered catalog files: the processor that stamps entities,
 * the table behind it on an in-memory SQLite database, and the recorder in
 * front of a stand-in for the catalog's locations API.
 */

import { randomUUID } from 'crypto';
import type { Server } from 'http';
import type { AddressInfo } from 'net';
import express from 'express';
import knexFactory, { Knex } from 'knex';
import { MiddlewareFactory } from '@backstage/backend-defaults/rootHttpRouter';
import type { LoggerService } from '@backstage/backend-plugin-api';
import type { Entity } from '@backstage/catalog-model';
import { ConfigReader } from '@backstage/config';
import {
  AccountStampProcessor,
  LocationAccountsStore,
  handOverEarlierFiles,
} from '../accounts/catalogModule';
import {
  createRegistrationRecorder,
  mountRecorder,
  type RegistrationRecorder,
} from '../accounts/recordRegistrations';

const JANE = 'user:default/jane';
const KIM = 'user:default/kim';
const ORGANISATION = 'organisation:0123456789abcdef0123456789abcdef';
const FILE = 'https://github.com/acme/app/blob/main/catalog-info.yaml';
const OTHER = 'https://github.com/acme/other/blob/main/catalog-info.yaml';
/** Where the app is served from, which is not where the backend is. */
const APP_ORIGIN = 'http://localhost:3000';

async function catalogDatabase(): Promise<Knex> {
  const knex = knexFactory({
    client: 'better-sqlite3',
    connection: ':memory:',
    useNullAsDefault: true,
  });
  // The columns of the catalog's own tables that the store reads.
  await knex.schema.createTable('locations', table => {
    table.string('id').primary();
    table.string('type').notNullable();
    table.string('target').notNullable();
    table.string('location_entity_ref').notNullable();
  });
  await knex('locations').insert({
    id: 'bootstrap-id',
    type: 'bootstrap',
    target: 'bootstrap',
    location_entity_ref: '',
  });
  await knex.schema.createTable('refresh_state', table => {
    table.string('entity_ref').primary();
    table.text('location_key');
    table.text('processed_entity');
  });
  await knex.schema.createTable('refresh_state_references', table => {
    table.increments('id');
    table.text('source_key');
    table.text('source_entity_ref');
    table.text('target_entity_ref').notNullable();
  });
  return knex;
}

/**
 * Puts an entity in the catalog as the catalog records it: read from the
 * file at `readFrom`, produced by an entity (`by`) or, for the first of a
 * line, by what the catalog calls the source (`source`).
 */
async function produce(
  knex: Knex,
  entityRef: string,
  from: { by?: string; source?: string; readFrom?: string },
) {
  await knex('refresh_state')
    .insert({
      entity_ref: entityRef,
      location_key: from.readFrom ? `url:${from.readFrom}` : null,
    })
    .onConflict('entity_ref')
    .ignore();
  await knex('refresh_state_references').insert({
    source_key: from.source ?? null,
    source_entity_ref: from.by ?? null,
    target_entity_ref: entityRef,
  });
}

const fileEntity = (id: string) => `location:default/generated-${id}`;

/** Registers the file at `target`, as the catalog does. */
async function register(knex: Knex, target: string, id = `id-of-${target}`) {
  await knex('locations').insert({
    id,
    type: 'url',
    target,
    location_entity_ref: fileEntity(id),
  });
  await produce(knex, fileEntity(id), {
    source: 'DefaultLocationStore',
    readFrom: target,
  });
  return id;
}

/** Unregisters the file with this id, as the catalog does. */
async function unregister(knex: Knex, id: string) {
  await knex('locations').where({ id }).delete();
  await knex('refresh_state_references')
    .where({ target_entity_ref: fileEntity(id) })
    .orWhere({ source_entity_ref: fileEntity(id) })
    .delete();
  await knex('refresh_state')
    .where({ entity_ref: fileEntity(id) })
    .delete();
}

/** The stamp on what the registered file at `target` produces. */
async function stampOfFile(
  knex: Knex,
  store: LocationAccountsStore,
  target: string,
) {
  const row = await knex('locations')
    .where({ type: 'url', target })
    .first('location_entity_ref');
  return row ? store.stampFor(row.location_entity_ref) : undefined;
}

describe('AccountStampProcessor', () => {
  const APP = 'component:default/app';
  const AT = { type: 'url', target: FILE };
  const entity = (
    annotations?: Record<string, string>,
    metadata: Record<string, unknown> = {},
  ): Entity =>
    ({
      apiVersion: 'backstage.io/v1alpha1',
      kind: 'Component',
      metadata: { name: 'app', annotations, ...metadata },
      spec: { type: 'service', lifecycle: 'production', owner: 'team' },
    } as Entity);

  /** What the processor reported as wrong with the last entity. */
  let refused: string[];
  const stamp = (
    processed: Entity,
    accounts: Record<string, string>,
    catalog: { registered?: string[]; held?: string[] } = {},
  ) => {
    refused = [];
    return new AccountStampProcessor(
      {
        stampFor: async entityRef => accounts[entityRef],
        isRegisteredFile: async entityRef =>
          catalog.registered?.includes(entityRef) ?? false,
        heldElsewhere: async target => catalog.held?.includes(target) ?? false,
      },
      (url, base) => new URL(url, base).toString(),
    ).preProcessEntity(processed, AT, result => {
      if (result.type === 'error') {
        refused.push(result.error.message);
      }
    });
  };

  it('stamps the account of the registered file an entity comes from', async () => {
    const stamped = await stamp(entity({ 'example.com/kept': 'yes' }), {
      [APP]: ORGANISATION,
    });
    expect(stamped.metadata.annotations).toEqual({
      'example.com/kept': 'yes',
      'portal/account': ORGANISATION,
    });
  });

  it('writes its own answer over what the file said, in any spelling', async () => {
    const stamped = await stamp(
      entity({ 'portal/account': KIM, 'Portal/Account': KIM }),
      { [APP]: JANE },
    );
    expect(stamped.metadata.annotations).toEqual({ 'portal/account': JANE });
  });

  it('stamps an entity of a registered file nobody has taken as unclaimed', async () => {
    const stamped = await stamp(entity(), { [APP]: 'unclaimed' });
    expect(stamped.metadata.annotations).toEqual({
      'portal/account': 'unclaimed',
    });
  });

  it('removes the annotation from an entity that comes from no registered file', async () => {
    const stamped = await stamp(
      entity({ 'portal/account': JANE, 'PORTAL/ACCOUNT': JANE }),
      {},
    );
    expect(stamped.metadata.annotations).toEqual({});
  });

  it('removes every other key the catalog would index as the annotation', async () => {
    // The catalog flattens metadata to `metadata.annotations.portal/account`
    // for each of these, the key the permission policy filters on.
    const smuggled = {
      'annotations.portal/account': ORGANISATION,
      'Annotations.Portal/Account': ORGANISATION,
      Annotations: { 'portal/account': ORGANISATION },
      title: 'kept',
    };
    const shared = await stamp(entity(undefined, smuggled), {});
    expect(shared.metadata).toEqual({
      name: 'app',
      title: 'kept',
      annotations: {},
    });
    const filed = await stamp(entity({ kept: 'yes' }, smuggled), {
      [APP]: JANE,
    });
    expect(filed.metadata).toEqual({
      name: 'app',
      title: 'kept',
      annotations: { kept: 'yes', 'portal/account': JANE },
    });
  });

  it('lets only the catalog say an entity of a registered file is an orphan', async () => {
    const orphan = { 'backstage.io/orphan': 'true' };
    const filed = await stamp(entity(orphan), { [APP]: JANE });
    expect(filed.metadata.annotations).toEqual({ 'portal/account': JANE });
    const shared = entity(orphan);
    expect(await stamp(shared, {})).toBe(shared);
  });

  it('leaves an entity with nothing to change as it is', async () => {
    const untouched = entity({ 'example.com/kept': 'yes' });
    expect(await stamp(untouched, {})).toBe(untouched);
    const notAnEntity = { kind: 'Component' } as Entity;
    expect(await stamp(notAnEntity, {})).toBe(notAnEntity);
  });

  describe('for the documentation of an entity', () => {
    const DOCS = 'backstage.io/techdocs-ref';
    const SOURCE = 'backstage.io/source-location';
    /** The annotations left on an entity of Jane's registered file. */
    const filed = async (annotations: Record<string, string>) => {
      const { 'portal/account': account, ...rest } =
        (await stamp(entity(annotations), { [APP]: JANE })).metadata
          .annotations ?? {};
      expect(account).toBe(JANE);
      return rest;
    };

    it('removes a reference to another repository', async () => {
      for (const elsewhere of [
        'url:https://github.com/acme/other/tree/main/docs',
        'url:https://github.com/somebody/app/tree/main',
        'url:https://example.com/acme/app/tree/main',
        // Its own repository only as a user name, or behind a backslash.
        'url:https://github.com/acme/app@example.com/acme/other',
        'url:https://example.com\\@github.com/acme/app',
        // No repository at all.
        'url:https://github.com/acme',
        ' url : https://github.com/acme/other ',
      ]) {
        expect(await filed({ [DOCS]: elsewhere, kept: 'yes' })).toEqual({
          kept: 'yes',
        });
      }
    });

    it('keeps a reference to the repository the entity’s file is in', async () => {
      for (const own of [
        'url:https://github.com/acme/app/tree/main/docs',
        'url:https://GitHub.com/Acme/App',
        'dir:.',
        'dir:./docs',
        'dir:../docs',
      ]) {
        expect(await filed({ [DOCS]: own })).toEqual({ [DOCS]: own });
      }
    });

    it('removes a directory that is outside the repository', async () => {
      // Up and out of the repository.
      expect(
        await filed({ [DOCS]: 'dir:../../../../acme/other/tree/main' }),
      ).toEqual({});
      // The documentation builder reads a directory from the source
      // location when the file sets one.
      const moved = {
        [SOURCE]: 'url:https://github.com/acme/other/tree/main/',
      };
      expect(await filed({ [DOCS]: 'dir:.', ...moved })).toEqual(moved);
      const local = { [SOURCE]: 'file:/etc/portal/' };
      expect(await filed({ [DOCS]: 'dir:.', ...local })).toEqual(local);
      const same = { [SOURCE]: 'url:https://github.com/acme/app/tree/main/' };
      expect(await filed({ [DOCS]: 'dir:docs', ...same })).toEqual({
        [DOCS]: 'dir:docs',
        ...same,
      });
    });

    it('leaves what the documentation builder does not read', async () => {
      const unread = { [DOCS]: 'https://github.com/acme/other' };
      expect(await filed(unread)).toEqual(unread);
    });

    it('leaves an entity the operator configured as it is', async () => {
      const shared = entity({
        [DOCS]: 'url:https://github.com/acme/other/tree/main/docs',
      });
      expect(await stamp(shared, {})).toBe(shared);
    });
  });

  describe('for a Location entry in a registered file', () => {
    const MORE = 'location:default/more';
    const HELD = 'https://github.com/acme/app/blob/main/held.yaml';
    const more = (spec: Record<string, unknown>): Entity =>
      ({
        apiVersion: 'backstage.io/v1alpha1',
        kind: 'Location',
        metadata: { name: 'more' },
        spec,
      } as Entity);

    it('lets it read files whose entries are nowhere else yet', async () => {
      const read = await stamp(
        more({ target: './free.yaml', targets: ['./also-free.yaml'] }),
        { [MORE]: JANE },
        { held: [HELD] },
      );
      expect(read.spec).toEqual({
        target: './free.yaml',
        targets: ['./also-free.yaml'],
      });
      expect(refused).toEqual([]);
    });

    it('keeps it from files whose entries are in the catalog from elsewhere', async () => {
      const read = await stamp(
        more({ target: './held.yaml', targets: [HELD, './free.yaml'] }),
        { [MORE]: JANE },
        { held: [HELD] },
      );
      expect(read.spec).toEqual({ targets: ['./free.yaml'] });
      expect(refused).toEqual([
        `${HELD} is in the catalog already from somewhere else, so it is not included again`,
        `${HELD} is in the catalog already from somewhere else, so it is not included again`,
      ]);
    });

    it('keeps it from wildcards and from files that are not at a url', async () => {
      const wildcard = await stamp(
        more({ targets: ['./**/catalog-info.yaml', './free.yaml'] }),
        { [MORE]: JANE },
      );
      expect(wildcard.spec).toEqual({ targets: ['./free.yaml'] });
      expect(refused).toHaveLength(1);

      const local = await stamp(more({ type: 'file', target: '/etc/passwd' }), {
        [MORE]: JANE,
      });
      expect(local.spec).toEqual({ type: 'file', targets: [] });
      expect(refused).toHaveLength(1);
    });

    it('leaves the registered file itself, and what the operator provides, alone', async () => {
      const spec = { targets: [HELD, './**/catalog-info.yaml'] };
      const itself = await stamp(
        more(spec),
        { [MORE]: JANE },
        { registered: [MORE], held: [HELD] },
      );
      expect(itself.spec).toEqual(spec);
      const provided = more(spec);
      expect(await stamp(provided, {}, { held: [HELD] })).toBe(provided);
      expect(refused).toEqual([]);
    });
  });
});

describe('LocationAccountsStore', () => {
  let knex: Knex;
  let store: LocationAccountsStore;

  beforeEach(async () => {
    knex = await catalogDatabase();
    store = new LocationAccountsStore(knex);
    await store.initialise();
  });
  afterEach(() => knex.destroy());

  it('answers the processor: account, unclaimed, or not registered', async () => {
    const id = await register(knex, FILE);
    await register(knex, OTHER);
    await store.claim(FILE, JANE);
    expect(await stampOfFile(knex, store, FILE)).toBe(JANE);
    expect(await stampOfFile(knex, store, OTHER)).toBe('unclaimed');
    expect(await store.stampFor('component:default/unknown')).toBe(undefined);
    expect(await store.isRegisteredFile(fileEntity(id))).toBe(true);
    expect(await store.isRegisteredFile('location:default/more')).toBe(false);

    // Whatever the file produces, however far down, is the account's too.
    await produce(knex, 'location:default/more', { by: fileEntity(id) });
    await produce(knex, 'component:default/app', {
      by: 'location:default/more',
    });
    expect(await store.stampFor('component:default/app')).toBe(JANE);
  });

  it('does not stamp what the operator provides, whoever registers its address', async () => {
    // The organisation sync gives each team an address; anybody can
    // register that address.
    const team = 'https://github.com/orgs/acme/teams/platform';
    await produce(knex, 'group:default/platform', {
      source: 'GithubOrgEntityProvider:default',
    });
    const id = await register(knex, team);
    await store.claim(team, JANE);
    expect(await store.stampFor('group:default/platform')).toBe(undefined);

    // Nor an entry that a registered file reads besides the operator.
    await produce(knex, 'location:default/config', {
      source: 'ConfigLocationProvider',
    });
    await produce(knex, 'group:default/admins', {
      by: 'location:default/config',
    });
    await produce(knex, 'group:default/admins', { by: fileEntity(id) });
    expect(await store.stampFor('group:default/admins')).toBe(undefined);
  });

  it('shows nobody what two accounts both produce, or what a file that is gone produced', async () => {
    const janes = await register(knex, FILE);
    const kims = await register(knex, OTHER);
    await store.claim(FILE, JANE);
    await store.claim(OTHER, KIM);
    await produce(knex, 'component:default/both', { by: fileEntity(janes) });
    await produce(knex, 'component:default/both', { by: fileEntity(kims) });
    expect(await store.stampFor('component:default/both')).toBe('unclaimed');

    await produce(knex, 'component:default/app', { by: fileEntity(kims) });
    await knex('locations').where({ id: kims }).delete();
    expect(await store.stampFor('component:default/app')).toBe('unclaimed');
  });

  it('keeps the stamp of an entity nothing produces any more', async () => {
    await knex('refresh_state').insert([
      {
        entity_ref: 'component:default/was-janes',
        processed_entity: JSON.stringify({
          metadata: { annotations: { 'portal/account': JANE } },
        }),
      },
      {
        entity_ref: 'component:default/was-shared',
        processed_entity: JSON.stringify({ metadata: { annotations: {} } }),
      },
      { entity_ref: 'component:default/never-processed' },
    ]);
    expect(await store.stampFor('component:default/was-janes')).toBe(JANE);
    expect(await store.stampFor('component:default/was-shared')).toBe(
      undefined,
    );
    expect(await store.stampFor('component:default/never-processed')).toBe(
      undefined,
    );
  });

  it('tells whether the entries of a file are in the catalog from elsewhere', async () => {
    const id = await register(knex, FILE);
    await produce(knex, 'component:default/app', {
      by: fileEntity(id),
      readFrom: OTHER,
    });
    expect(await store.heldElsewhere(OTHER)).toBe(true);
    expect(await store.heldElsewhere(OTHER, 'location:default/more')).toBe(
      true,
    );
    expect(await store.heldElsewhere(OTHER, fileEntity(id))).toBe(false);
    // The file's own entity is produced by the catalog, not by an entity.
    expect(await store.heldElsewhere(FILE, fileEntity(id))).toBe(true);
    expect(await store.heldElsewhere('https://example.com/free.yaml')).toBe(
      false,
    );
    // An entry nothing produces any more holds nothing.
    await knex('refresh_state').insert({
      entity_ref: 'component:default/left',
      location_key: 'url:https://example.com/left.yaml',
    });
    expect(await store.heldElsewhere('https://example.com/left.yaml')).toBe(
      false,
    );
  });

  it('does not let a file that is somebody’s be taken', async () => {
    await register(knex, FILE);
    await store.claim(FILE, JANE);
    await store.claim(FILE, KIM);
    expect(await store.accountOf(FILE)).toBe(JANE);
  });

  it('forgets an account only once the file is unregistered', async () => {
    const id = await register(knex, FILE);
    await store.claim(FILE, JANE);
    await store.forget(FILE);
    expect(await store.accountOf(FILE)).toBe(JANE);
    await knex('locations').where({ id }).delete();
    await store.forget(FILE);
    expect(await store.accountOf(FILE)).toBe(undefined);
  });

  it('follows a file to its new address', async () => {
    await register(knex, FILE);
    await store.claim(FILE, JANE);
    await store.claim(OTHER, KIM);
    await store.retarget(FILE, OTHER);
    expect(await store.accountOf(FILE)).toBe(undefined);
    expect(await store.accountOf(OTHER)).toBe(JANE);
  });

  it('moves everything of one account to another', async () => {
    await store.claim(FILE, ORGANISATION);
    await store.claim(OTHER, KIM);
    expect(await store.moveAccount(ORGANISATION, JANE)).toEqual([FILE]);
    expect(await store.moveAccount(ORGANISATION, JANE)).toEqual([]);
    expect(await store.targetsOf([JANE])).toEqual([FILE]);
    expect(await store.targetsOf([KIM, ORGANISATION])).toEqual([OTHER]);
    expect(await store.targetsOf([])).toEqual([]);
  });

  it('lists the registered files that have no account', async () => {
    await register(knex, FILE);
    await register(knex, OTHER);
    await store.claim(OTHER, KIM);
    // The note of a hand-over still to do is not an account of any file.
    await knex('location_accounts').insert({
      target: ':legacy',
      account: 'pending',
    });
    expect(await store.unclaimedTargets()).toEqual([FILE]);
  });

  it('finds a registered file by its id, and nothing for an id that is none', async () => {
    const id = await register(knex, FILE);
    expect(await store.locationById(id)).toEqual({ type: 'url', target: FILE });
    expect(await store.locationById('no-such-id')).toBe(undefined);
    expect(await store.entityRefOf(FILE)).toBe(
      `location:default/generated-${id}`,
    );
  });
});

describe('files registered before accounts existed', () => {
  let knex: Knex;
  let store: LocationAccountsStore;
  const ADMIN = 'user:default/ada';

  /** A portal with these administrators, where ada is in the organisation. */
  const portal = (admins: string[]) => ({
    portalAdmins: async () => admins,
    accountFor: async (userRef: string) =>
      userRef === ADMIN ? ORGANISATION : userRef,
  });
  const accountRows = () =>
    knex('location_accounts').orderBy('target').select('target', 'account');

  beforeEach(async () => {
    knex = await catalogDatabase();
    store = new LocationAccountsStore(knex);
  });
  afterEach(() => knex.destroy());

  it('has nothing to hand over on a new portal', async () => {
    await store.initialise();
    await register(knex, FILE);
    expect(await handOverEarlierFiles(store, portal([ADMIN]))).toEqual({
      outcome: 'not-needed',
    });
    expect(await accountRows()).toEqual([]);
    expect(await stampOfFile(knex, store, FILE)).toBe('unclaimed');
  });

  it('has nothing to hand over before the catalog has made its tables', async () => {
    await knex.schema.dropTable('locations');
    await store.initialise();
    expect(await accountRows()).toEqual([]);
  });

  it('hands them to the first administrator who is a person, under their organisation', async () => {
    await register(knex, FILE);
    await register(knex, OTHER);
    await store.initialise();
    // A file registered after the upgrade keeps the account it was given.
    await store.claim(OTHER, KIM);

    expect(
      await handOverEarlierFiles(
        store,
        portal(['group:default/platform', ADMIN, KIM]),
      ),
    ).toEqual({ outcome: 'handed-over', files: 1, account: ORGANISATION });
    expect(await accountRows()).toEqual([
      { target: FILE, account: ORGANISATION },
      { target: OTHER, account: KIM },
    ]);
    expect(await stampOfFile(knex, store, FILE)).toBe(ORGANISATION);
  });

  it('leaves them, still to hand over, while no person administers the portal', async () => {
    await register(knex, FILE);
    await store.initialise();
    expect(
      await handOverEarlierFiles(store, portal(['group:default/platform'])),
    ).toEqual({ outcome: 'no-administrator' });
    expect(await stampOfFile(knex, store, FILE)).toBe('unclaimed');
    expect(await store.handOverPending()).toBe(true);

    // After a restart with an administrator, it is done.
    await new LocationAccountsStore(knex).initialise();
    expect(await handOverEarlierFiles(store, portal([ADMIN]))).toEqual({
      outcome: 'handed-over',
      files: 1,
      account: ORGANISATION,
    });
  });

  it('hands over once: a second run changes nothing', async () => {
    await register(knex, FILE);
    await store.initialise();
    await handOverEarlierFiles(store, portal([ADMIN]));
    await register(knex, OTHER);

    await store.initialise();
    expect(await handOverEarlierFiles(store, portal([KIM]))).toEqual({
      outcome: 'not-needed',
    });
    expect(await accountRows()).toEqual([
      { target: FILE, account: ORGANISATION },
    ]);
  });

  it('never takes the note of the hand-over for a file', async () => {
    await register(knex, FILE);
    await store.initialise();
    // Somebody registers a file at the very address of the note.
    await register(knex, ':legacy');
    await store.claim(':legacy', JANE);
    await store.forget(':legacy');
    await store.retarget(':legacy', FILE);
    await store.moveAccount('pending', JANE);

    expect(await store.handOverPending()).toBe(true);
    expect(await stampOfFile(knex, store, ':legacy')).toBe('unclaimed');
    expect(await store.accountOf(':legacy')).toBe(undefined);
    expect(await store.targetsOf(['pending', JANE])).toEqual([]);

    await handOverEarlierFiles(store, portal([ADMIN]));
    expect(await accountRows()).toEqual([
      { target: FILE, account: ORGANISATION },
    ]);
  });
});

describe('registration recorder', () => {
  let knex: Knex;
  let store: LocationAccountsStore;
  let server: Server;
  let base: string;
  let refreshed: string[];
  /** Bodies the stand-in catalog received, as it parsed them itself. */
  let received: unknown[];
  let recorder: RegistrationRecorder;
  /** The one portal administrator, and whether that can be told just now. */
  const ADA = 'user:default/ada';
  let administratorsKnown: boolean;

  const encode = (part: unknown) =>
    Buffer.from(JSON.stringify(part)).toString('base64url');
  const userToken = (sub: string) =>
    `${encode({ typ: 'vnd.backstage.user', alg: 'ES256' })}.${encode({
      sub,
    })}.signature`;
  /** What one plugin sends another on a user's behalf, or on its own. */
  const pluginToken = (onBehalfOf?: string) =>
    `${encode({ typ: 'vnd.backstage.plugin', alg: 'ES256' })}.${encode({
      sub: 'scaffolder',
      obo: onBehalfOf
        ? `${encode({ typ: 'vnd.backstage.limited-user' })}.${encode({
            sub: onBehalfOf,
          })}.signature`
        : undefined,
    })}.signature`;

  async function call(
    token: string | undefined,
    method: string,
    path: string,
    json?: unknown,
  ) {
    const response = await fetch(`${base}/api/catalog${path}`, {
      method,
      headers: {
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        ...(json === undefined ? {} : { 'content-type': 'application/json' }),
      },
      body: json === undefined ? undefined : JSON.stringify(json),
    });
    const text = await response.text();
    // The recorder files the account once the response has gone out.
    await recorder.settled();
    return {
      status: response.status,
      body: text ? JSON.parse(text) : undefined,
    };
  }

  beforeEach(async () => {
    knex = await catalogDatabase();
    store = new LocationAccountsStore(knex);
    await store.initialise();
    refreshed = [];
    received = [];

    // A stand-in for the catalog: the same routes over the same table, a
    // JSON parser of its own, and 401 for a request with no token.
    const catalog = express.Router();
    catalog.use(express.json());
    catalog.use((req, res, next) => {
      if (req.headers.authorization) {
        next();
      } else {
        res.status(401).json({ error: { name: 'AuthenticationError' } });
      }
    });
    const shape = (row: { id: string; type: string; target: string }) => ({
      id: row.id,
      type: row.type,
      target: row.target,
    });
    const rows = () => knex('locations').whereNot('type', 'bootstrap');
    catalog.post('/locations', async (req, res) => {
      received.push(req.body);
      const { type, target } = req.body;
      const existing = await rows().where({ type, target }).first();
      if (req.query.dryRun === 'true') {
        res.status(201).json({
          exists: Boolean(existing),
          location: { type, target },
          entities: [
            {
              kind: 'Component',
              metadata: {
                name: 'app',
                annotations: {
                  kept: 'yes',
                  'portal/account': ORGANISATION,
                  'Portal/Account': ORGANISATION,
                },
              },
            },
          ],
        });
        return;
      }
      if (existing && req.query.onConflict !== 'refresh') {
        res.status(409).json({ error: { name: 'ConflictError' } });
        return;
      }
      const id = existing?.id ?? randomUUID();
      if (!existing) {
        await register(knex, target, id);
      }
      res.status(201).json({ location: { id, type, target }, entities: [] });
    });
    catalog.get('/locations', async (_req, res) => {
      res.json((await rows()).map(row => ({ data: shape(row) })));
    });
    catalog.post('/locations/by-query', async (req, res) => {
      received.push(req.body);
      const items = (await rows()).map(shape);
      res.json({ items, totalItems: items.length, pageInfo: {} });
    });
    catalog.get(
      '/locations/by-entity/:kind/:namespace/:name',
      async (req, res) => {
        const row = await rows().where({ id: req.params.name }).first();
        if (row) {
          res.json(shape(row));
        } else {
          res.status(404).json({ error: { name: 'NotFoundError' } });
        }
      },
    );
    // The registered file a request names, or the catalog's 404 for it.
    const found = async (req: express.Request, res: express.Response) => {
      const row = await rows().where({ id: req.params.id }).first();
      if (!row) {
        res.status(404).json({
          error: {
            name: 'NotFoundError',
            message: `Found no location with ID ${req.params.id}`,
          },
          // As the catalog names it: without the path it is served under.
          request: { method: req.method, url: req.url },
        });
      }
      return row;
    };
    catalog.get('/locations/:id', async (req, res) => {
      const row = await found(req, res);
      if (row) {
        res.json(shape(row));
      }
    });
    catalog.put('/locations/:id', async (req, res) => {
      if (await found(req, res)) {
        received.push(req.body);
        const { type, target } = req.body;
        await knex('locations')
          .where({ id: req.params.id })
          .update({ type, target });
        res.json({ id: req.params.id, type, target });
      }
    });
    catalog.delete('/locations/:id', async (req, res) => {
      if (await found(req, res)) {
        await unregister(knex, String(req.params.id));
        res.status(204).end();
      }
    });

    const app = express();
    recorder = createRegistrationRecorder({
      accounts: () => ({
        store,
        refresh: async target => {
          refreshed.push(target);
        },
      }),
      memberships: {
        accountsOf: async userRef =>
          userRef === KIM ? [KIM, ORGANISATION] : [userRef],
        accountFor: async userRef => (userRef === KIM ? ORGANISATION : userRef),
      },
      admins: {
        isPortalAdmin: async userRef => {
          if (!administratorsKnown) {
            throw new Error('The portal is still starting');
          }
          return userRef === ADA;
        },
      },
      logger: { error() {} },
    });
    // Mounted as in the backend, whose app is served from another origin.
    const quiet: LoggerService = {
      error() {},
      warn() {},
      info() {},
      debug() {},
      child: () => quiet,
    };
    mountRecorder(
      app,
      MiddlewareFactory.create({
        config: new ConfigReader({ backend: { cors: { origin: APP_ORIGIN } } }),
        logger: quiet,
      }),
      recorder.router,
    );
    app.use('/api/catalog', catalog);
    server = await new Promise<Server>(resolve => {
      const listening = app.listen(0, '127.0.0.1', () => resolve(listening));
    });
    base = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  });

  afterEach(async () => {
    await new Promise(resolve => server.close(resolve));
    await knex.destroy();
  });

  const location = { type: 'url', target: FILE };

  describe('for an app served from another origin', () => {
    const crossOrigin = (method: string, path: string, json?: unknown) =>
      fetch(`${base}/api/catalog${path}`, {
        method,
        headers: {
          origin: APP_ORIGIN,
          authorization: `Bearer ${userToken(JANE)}`,
          ...(method === 'OPTIONS'
            ? { 'access-control-request-method': 'POST' }
            : { 'content-type': 'application/json' }),
        },
        body: json === undefined ? undefined : JSON.stringify(json),
      });

    it('answers the preflight request for each of its paths', async () => {
      for (const path of [
        '/locations',
        '/locations/by-query',
        `/locations/${randomUUID()}`,
        '/locations/by-entity/component/default/app',
      ]) {
        const answer = await crossOrigin('OPTIONS', path);
        expect(answer.status).toBe(204);
        expect(answer.headers.get('access-control-allow-origin')).toBe(
          APP_ORIGIN,
        );
      }
    });

    it('lets the app read a refusal the recorder gives itself', async () => {
      const answer = await crossOrigin('POST', '/locations', {
        type: 'url',
        target: 'https://github.com/acme/app/blob/main/*/catalog-info.yaml',
      });
      expect(answer.status).toBe(400);
      expect(answer.headers.get('access-control-allow-origin')).toBe(
        APP_ORIGIN,
      );
      expect(answer.headers.get('x-content-type-options')).toBe('nosniff');
    });
  });

  it('files a registered file under the account of who registered it', async () => {
    const answer = await call(userToken(JANE), 'POST', '/locations', location);
    expect(answer.status).toBe(201);
    // The catalog still read the body itself.
    expect(received).toEqual([location]);
    expect(await store.accountOf(FILE)).toBe(JANE);
    expect(refreshed).toEqual([FILE]);
  });

  it('files a member’s file under their organisation', async () => {
    await call(userToken(KIM), 'POST', '/locations', location);
    expect(await store.accountOf(FILE)).toBe(ORGANISATION);
  });

  it('files what a template run registers under the user it runs for', async () => {
    await call(pluginToken(JANE), 'POST', '/locations', location);
    expect(await store.accountOf(FILE)).toBe(JANE);
  });

  it('leaves a file registered by no user without an account', async () => {
    const answer = await call(pluginToken(), 'POST', '/locations', location);
    expect(answer.status).toBe(201);
    expect(await store.accountOf(FILE)).toBe(undefined);
    expect(await stampOfFile(knex, store, FILE)).toBe('unclaimed');
  });

  it('records nothing for a dry run, a refusal, or a request with no token', async () => {
    await call(userToken(JANE), 'POST', '/locations?dryRun=true', location);
    expect(await store.accountOf(FILE)).toBe(undefined);

    await register(knex, FILE);
    expect(
      (await call(userToken(JANE), 'POST', '/locations', location)).status,
    ).toBe(409);
    expect(await store.accountOf(FILE)).toBe(undefined);

    expect((await call(undefined, 'POST', '/locations', location)).status).toBe(
      401,
    );
  });

  it('does not hand a registered file to someone who asks the catalog to refresh it', async () => {
    await call(userToken(JANE), 'POST', '/locations', location);
    const answer = await call(
      userToken(KIM),
      'POST',
      '/locations?onConflict=refresh&x=1',
      location,
    );
    // The catalog's own refusal of an address that is taken.
    expect(answer).toEqual({
      status: 409,
      body: { error: { name: 'ConflictError' } },
    });
    expect(await store.accountOf(FILE)).toBe(JANE);

    // Whose file it is may still ask.
    const own = await call(
      userToken(JANE),
      'POST',
      '/locations?onConflict=refresh',
      location,
    );
    expect(own.status).toBe(201);
    expect(own.body.location.target).toBe(FILE);
  });

  it('gives the file to one of two people who register it at once', async () => {
    const [first, second] = await Promise.all([
      call(userToken(JANE), 'POST', '/locations', location),
      call(userToken(KIM), 'POST', '/locations?onConflict=refresh', location),
    ]);
    expect([first.status, second.status]).toEqual([201, 409]);
    expect(await store.accountOf(FILE)).toBe(JANE);
  });

  it('refuses an address whose entries are in the catalog from elsewhere', async () => {
    // The address of a team the organisation sync provides, and a file an
    // entry of somebody's registered file reads.
    const team = 'https://github.com/orgs/acme/teams/platform';
    await produce(knex, 'group:default/platform', {
      source: 'GithubOrgEntityProvider:default',
      readFrom: team,
    });
    const answer = await call(userToken(JANE), 'POST', '/locations', {
      type: 'url',
      target: team,
    });
    expect(answer.status).toBe(409);
    expect(answer.body).toEqual({
      error: {
        name: 'ConflictError',
        message: `The entries of url:${team} are in the catalog already`,
      },
      request: { method: 'POST', url: '/locations' },
      response: { statusCode: 409 },
    });
    // Not passed on, so not registered.
    expect(received).toEqual([]);
    expect(await store.isRegistered(team)).toBe(false);

    // Nor may a file of the caller's own be moved there.
    const janes = (await call(userToken(JANE), 'POST', '/locations', location))
      .body.location.id;
    received = [];
    expect(
      (
        await call(userToken(JANE), 'PUT', `/locations/${janes}`, {
          type: 'url',
          target: team,
        })
      ).status,
    ).toBe(409);
    expect(received).toEqual([]);
    expect(await store.accountOf(FILE)).toBe(JANE);
  });

  it('refuses a wildcard, which could read anybody’s files', async () => {
    const answer = await call(userToken(JANE), 'POST', '/locations', {
      type: 'url',
      target: 'https://github.com/acme/app/blob/main/**/catalog-info.yaml',
    });
    expect(answer.status).toBe(400);
    expect(answer.body.error.name).toBe('InputError');
    expect(received).toEqual([]);
  });

  describe('a dry run', () => {
    const dryRun = async (token: string) =>
      (await call(token, 'POST', '/locations?dryRun=true', location)).body;
    const shown = [
      {
        kind: 'Component',
        metadata: { name: 'app', annotations: { kept: 'yes' } },
      },
    ];

    it('never says which account anything is filed under', async () => {
      expect(await dryRun(userToken(JANE))).toEqual({
        exists: false,
        location,
        entities: shown,
      });
      expect((await dryRun(pluginToken())).entities).toEqual(shown);
    });

    it('says a file is registered only to whose it is', async () => {
      await call(userToken(KIM), 'POST', '/locations', location);
      expect(await dryRun(userToken(KIM))).toEqual({
        exists: true,
        location,
        entities: shown,
      });
      expect(await dryRun(userToken(JANE))).toEqual({
        exists: false,
        location,
        entities: shown,
      });
    });
  });

  it('does not pass on the account of a file that was unregistered meanwhile', async () => {
    await store.claim(FILE, JANE);
    await call(userToken(KIM), 'POST', '/locations', location);
    expect(await store.accountOf(FILE)).toBe(ORGANISATION);
  });

  describe('with a file of each of two accounts', () => {
    let janes: string;
    let kims: string;

    beforeEach(async () => {
      janes = (await call(userToken(JANE), 'POST', '/locations', location)).body
        .location.id;
      kims = (
        await call(userToken(KIM), 'POST', '/locations', {
          type: 'url',
          target: OTHER,
        })
      ).body.location.id;
      received = [];
    });

    it('lists only the caller’s own, and all of them for the backend itself', async () => {
      const list = async (token: string) =>
        (await call(token, 'GET', '/locations')).body.map(
          (item: { data: { target: string } }) => item.data.target,
        );
      expect(await list(userToken(JANE))).toEqual([FILE]);
      expect(await list(userToken(KIM))).toEqual([OTHER]);
      expect(await list(pluginToken(JANE))).toEqual([FILE]);
      expect(await list(userToken('user:default/sam'))).toEqual([]);
      expect((await list(pluginToken())).sort()).toEqual([FILE, OTHER].sort());
    });

    it('narrows a query to the caller’s own, cursor or not', async () => {
      const own = { type: 'url', target: { $in: [FILE] } };
      const answer = await call(
        userToken(JANE),
        'POST',
        '/locations/by-query',
        {
          limit: 5,
          query: { type: 'url' },
        },
      );
      expect(answer.body.items.map((item: { id: string }) => item.id)).toEqual([
        janes,
      ]);
      expect(received).toEqual([
        { limit: 5, query: { $all: [{ type: 'url' }, own] } },
      ]);

      const cursor = Buffer.from(
        JSON.stringify({ limit: 5, afterId: 'a' }),
      ).toString('base64');
      await call(userToken(JANE), 'POST', '/locations/by-query', { cursor });
      const sent = received[1] as { cursor: string };
      expect(
        JSON.parse(Buffer.from(sent.cursor, 'base64').toString('utf8')),
      ).toEqual({ limit: 5, afterId: 'a', query: own });

      await call(userToken(JANE), 'POST', '/locations/by-query', []);
      expect(received[2]).toEqual({ query: own });
    });

    it('answers 404 for another account’s file, read, changed or unregistered', async () => {
      expect(
        (await call(userToken(JANE), 'GET', `/locations/${janes}`)).status,
      ).toBe(200);
      const read = await call(userToken(JANE), 'GET', `/locations/${kims}?x=1`);
      expect(read.status).toBe(404);
      // The catalog's own answer, naming the id that was asked for.
      expect(read.body).toEqual({
        error: {
          name: 'NotFoundError',
          message: `Found no location with ID ${kims}`,
        },
        request: { method: 'GET', url: `/locations/${kims}?x=1` },
      });
      // With no token it is the catalog's refusal, as for any file.
      expect(
        (await call(undefined, 'DELETE', `/locations/${kims}`)).status,
      ).toBe(401);
      expect(
        (
          await call(userToken(JANE), 'PUT', `/locations/${kims}`, {
            type: 'url',
            target: 'https://example.com/taken.yaml',
          })
        ).status,
      ).toBe(404);
      expect(
        (await call(userToken(JANE), 'DELETE', `/locations/${kims}`)).status,
      ).toBe(404);
      expect(await store.locationById(kims)).toEqual({
        type: 'url',
        target: OTHER,
      });
      expect(received).toEqual([]);
    });

    it('answers 404 for the file of an entity of another account', async () => {
      const mine = await call(
        userToken(JANE),
        'GET',
        `/locations/by-entity/component/default/${janes}`,
      );
      expect(mine.status).toBe(200);
      const theirs = await call(
        userToken(JANE),
        'GET',
        `/locations/by-entity/Component/default/${kims}`,
      );
      expect(theirs.status).toBe(404);
      // In full the answer the catalog gives for an entity that has no file.
      expect(theirs.body).toEqual({
        error: {
          name: 'NotFoundError',
          message: `found no entity for ref component:default/${kims}`,
        },
        request: {
          method: 'GET',
          url: `/locations/by-entity/Component/default/${kims}`,
        },
        response: { statusCode: 404 },
      });
    });

    it('takes an id in any other spelling for no file of the caller’s', async () => {
      // The database would take each of these for the same id.
      const spellings = [
        janes.toUpperCase(),
        `{${janes}}`,
        janes.replaceAll('-', ''),
      ];
      for (const spelling of spellings) {
        await knex('locations').insert({
          id: spelling,
          type: 'url',
          target: `https://example.com/${encodeURIComponent(spelling)}.yaml`,
          location_entity_ref: fileEntity(spelling),
        });
        for (const method of ['GET', 'DELETE']) {
          const answer = await call(
            userToken(JANE),
            method,
            `/locations/${encodeURIComponent(spelling)}`,
          );
          expect(answer.status).toBe(404);
          expect(answer.body.error.message).toBe(
            `Found no location with ID ${spelling}`,
          );
        }
        expect(await store.locationById(spelling)).toBeDefined();
      }
      // The backend's own plugins are not held to it.
      expect(
        (await call(pluginToken(), 'GET', `/locations/${spellings[0]}`)).status,
      ).toBe(200);
    });

    it('follows a file whose address is changed, and drops one that is unregistered', async () => {
      const moved = 'https://github.com/acme/app/blob/main/moved.yaml';
      const change = { type: 'url', target: moved };
      expect(
        (await call(userToken(JANE), 'PUT', `/locations/${janes}`, change))
          .status,
      ).toBe(200);
      expect(received).toEqual([change]);
      expect(await store.accountOf(FILE)).toBe(undefined);
      expect(await store.accountOf(moved)).toBe(JANE);

      expect(
        (await call(userToken(KIM), 'DELETE', `/locations/${kims}`)).status,
      ).toBe(204);
      expect(await store.accountOf(OTHER)).toBe(undefined);
    });
  });

  describe('with a file that has no account', () => {
    const NOBODYS = 'https://github.com/acme/left/blob/main/catalog-info.yaml';
    let janes: string;
    let nobodys: string;

    beforeEach(async () => {
      administratorsKnown = true;
      janes = (await call(userToken(JANE), 'POST', '/locations', location)).body
        .location.id;
      nobodys = (
        await call(pluginToken(), 'POST', '/locations', {
          type: 'url',
          target: NOBODYS,
        })
      ).body.location.id;
      received = [];
    });

    const listed = async (user: string) =>
      (await call(userToken(user), 'GET', '/locations')).body.map(
        (item: { data: { target: string } }) => item.data.target,
      );
    const found = async (user: string) =>
      (
        await call(userToken(user), 'POST', '/locations/by-query', {})
      ).body.items.map((item: { target: string }) => item.target);
    const statusOf = async (user: string, method: string, path: string) =>
      (await call(userToken(user), method, path)).status;

    it('lets a portal administrator see it and unregister it', async () => {
      expect(await listed(ADA)).toEqual([NOBODYS]);
      expect(await found(ADA)).toEqual([NOBODYS]);
      expect(received).toEqual([
        { query: { type: 'url', target: { $in: [NOBODYS] } } },
      ]);
      expect(await statusOf(ADA, 'GET', `/locations/${nobodys}`)).toBe(200);
      expect(
        await statusOf(
          ADA,
          'GET',
          `/locations/by-entity/component/default/${nobodys}`,
        ),
      ).toBe(200);

      expect(await statusOf(ADA, 'DELETE', `/locations/${nobodys}`)).toBe(204);
      expect(await store.locationById(nobodys)).toBe(undefined);
      expect(await listed(ADA)).toEqual([]);
    });

    it('keeps its entities hidden, and its address unchangeable, even so', async () => {
      expect(await stampOfFile(knex, store, NOBODYS)).toBe('unclaimed');
      const change = {
        type: 'url',
        target: 'https://example.com/taken.yaml',
      };
      expect(
        (await call(userToken(ADA), 'PUT', `/locations/${nobodys}`, change))
          .status,
      ).toBe(404);
      expect(await store.locationById(nobodys)).toEqual({
        type: 'url',
        target: NOBODYS,
      });
    });

    it('shows it to nobody who is not a portal administrator', async () => {
      expect(await listed(JANE)).toEqual([FILE]);
      expect(await found(JANE)).toEqual([FILE]);
      expect(await statusOf(JANE, 'GET', `/locations/${nobodys}`)).toBe(404);
      expect(
        await statusOf(
          JANE,
          'GET',
          `/locations/by-entity/component/default/${nobodys}`,
        ),
      ).toBe(404);
      expect(await statusOf(JANE, 'DELETE', `/locations/${nobodys}`)).toBe(404);
      expect(await store.locationById(nobodys)).toEqual({
        type: 'url',
        target: NOBODYS,
      });
    });

    it('shows a portal administrator no file of another account', async () => {
      expect(await listed(ADA)).not.toContain(FILE);
      expect(await found(ADA)).not.toContain(FILE);
      expect(await statusOf(ADA, 'GET', `/locations/${janes}`)).toBe(404);
      expect(
        await statusOf(
          ADA,
          'GET',
          `/locations/by-entity/component/default/${janes}`,
        ),
      ).toBe(404);
      expect(await statusOf(ADA, 'DELETE', `/locations/${janes}`)).toBe(404);
      expect(await store.accountOf(FILE)).toBe(JANE);
    });

    it('takes nobody for an administrator while that cannot be told', async () => {
      administratorsKnown = false;
      expect(await listed(ADA)).toEqual([]);
      expect(await statusOf(ADA, 'GET', `/locations/${nobodys}`)).toBe(404);
      expect(await statusOf(ADA, 'DELETE', `/locations/${nobodys}`)).toBe(404);
    });
  });
});
