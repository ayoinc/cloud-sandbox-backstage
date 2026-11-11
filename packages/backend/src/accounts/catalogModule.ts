/**
 * Catalog accounts module: keeps which account each registered catalog file
 * belongs to, and stamps that account on every entity that comes from it.
 *
 * The catalog keeps the files people register through the portal in its
 * `locations` table. This module adds `location_accounts` beside it, one row
 * per registered file that somebody has taken, and a processor that writes
 * the `portal/account` annotation from that row. The permission policy
 * (../permissionPolicy.ts) shows an entity only to the accounts its
 * annotation names, so the annotation is never taken from a catalog file:
 * the processor removes whatever the file said and writes its own answer.
 *
 * Which registered file an entity comes from is read from the catalog's own
 * record of what produced what (`refresh_state_references`), not from the
 * address the entity says it has: the GitHub organisation sync and the
 * files named in the configuration produce entities with addresses too,
 * and anybody can register an address.
 *
 * The catalog lets whichever file read an entry last have it. So that a
 * registered file cannot take entries that are in the catalog from
 * somewhere else, neither the file itself (the registration recorder
 * refuses it) nor a Location entry inside it (the processor refuses it)
 * may read an address whose entries are already there, or a wildcard,
 * whose addresses cannot be known beforehand.
 *
 * Rows are written by the registration recorder (./recordRegistrations.ts),
 * which watches the catalog's own locations API.
 */

import {
  coreServices,
  createBackendModule,
} from '@backstage/backend-plugin-api';
import {
  parseLocationRef,
  stringifyEntityRef,
  type Entity,
} from '@backstage/catalog-model';
import { ScmIntegrations } from '@backstage/integration';
import {
  catalogProcessingExtensionPoint,
  catalogServiceRef,
  processingResult,
  type CatalogProcessor,
  type CatalogProcessorEmit,
  type LocationSpec,
} from '@backstage/plugin-catalog-node';
import type { Knex } from 'knex';
import {
  ACCOUNT_ANNOTATION,
  UNCLAIMED_ACCOUNT,
  directory,
  provide,
  type Memberships,
  type PortalAdmins,
} from './directory';

/** The name under which the catalog records what registered files produce. */
const REGISTERED_FILES = 'DefaultLocationStore';

/** The annotation the catalog itself puts on an entity nothing produces any more. */
const ORPHAN_ANNOTATION = 'backstage.io/orphan';

/** The annotation that says where an entity's documentation is read from. */
const DOCS_ANNOTATION = 'backstage.io/techdocs-ref';

/**
 * The annotation a file may set to say where an entity's source is; the
 * documentation builder reads a `dir:` reference from there when it is set.
 */
const SOURCE_ANNOTATION = 'backstage.io/source-location';

/** `type:target` as the catalog splits it, or undefined when it is not one. */
function referenceIn(value: unknown): LocationSpec | undefined {
  if (typeof value !== 'string') {
    return undefined;
  }
  try {
    return parseLocationRef(value);
  } catch {
    return undefined;
  }
}

/**
 * The repository an address is in: its host and the first two parts of its
 * path, in lower case. Undefined for an address that names none, or that
 * could be read as naming another (a user name, a backslash).
 */
export function repositoryOf(address: string): string | undefined {
  if (address.includes('\\')) {
    return undefined;
  }
  let url: URL;
  try {
    url = new URL(address);
  } catch {
    return undefined;
  }
  const [owner, name] = url.pathname.split('/').filter(Boolean);
  if (url.username || url.password || !owner || !name) {
    return undefined;
  }
  return `${url.host}/${owner}/${name}`.toLowerCase();
}

/**
 * Whether reading the address may read several files. The catalog's
 * readers take `*` and `?` in the path for a wildcard; an address that
 * might be one is taken for one.
 */
export function isWildcard(target: string): boolean {
  const query = target.indexOf('?');
  return (
    target.includes('*') ||
    /%2a|%3f/i.test(target) ||
    (query >= 0 && target.includes('?', query + 1))
  );
}

/**
 * The row that says the files registered before accounts existed are still
 * to be handed over. It is not a file's row: no method below reads it as
 * one or lets it be written as one, even if somebody registers a file at
 * this very address.
 */
const HAND_OVER = { target: ':legacy', account: 'pending' };

/** A row of the catalog's `locations` table: a file registered through the portal. */
export interface RegisteredLocation {
  type: string;
  target: string;
}

/** What the processor needs to know from the catalog's database. */
export interface AccountStamps {
  /**
   * The account to stamp on the entity: that of the registered file it
   * comes from, `unclaimed` when nobody has taken the file, or undefined
   * when the entity comes from no registered file.
   */
  stampFor(entityRef: string): Promise<string | undefined>;
  /** Whether the entity is the one the catalog keeps for a registered file. */
  isRegisteredFile(entityRef: string): Promise<boolean>;
  /**
   * Whether entries read from the file at `target` are in the catalog
   * already, produced by anything other than the entity `except`.
   */
  heldElsewhere(target: string, except?: string): Promise<boolean>;
}

/**
 * Sets the `portal/account` annotation on every entity, whatever its file
 * said: the account of the registered file the entity comes from, or no
 * annotation when it comes from anywhere else (files named in the
 * configuration, entity providers), which the operator chose to share.
 *
 * For an entity of a registered file it also removes the orphan annotation,
 * which only the catalog may set, removes a documentation reference that
 * reads from outside the repository the entity's file is in, and keeps a
 * Location entry from reading files whose entries belong elsewhere.
 */
export class AccountStampProcessor implements CatalogProcessor {
  /**
   * `resolveUrl` gives the address `url` has when written in the file at
   * `base`, as the catalog works it out.
   */
  constructor(
    private readonly stamps: AccountStamps,
    private readonly resolveUrl: (url: string, base: string) => string,
  ) {}

  getProcessorName(): string {
    return 'AccountStampProcessor';
  }

  async preProcessEntity(
    entity: Entity,
    location: LocationSpec,
    emit: CatalogProcessorEmit,
  ): Promise<Entity> {
    let entityRef: string;
    try {
      entityRef = stringifyEntityRef(entity);
    } catch {
      // Not an entity yet; the catalog turns it down at its next step.
      return entity;
    }
    const account = await this.stamps.stampFor(entityRef);
    let changed = account !== undefined;

    // The catalog indexes an entity by its flattened keys in lower case:
    // `metadata: { "annotations.portal/account": … }` and
    // `metadata: { Annotations: { … } }` both land on the key the policy
    // filters on. No such spelling is left on any entity.
    const metadata = { ...entity.metadata };
    for (const key of Object.keys(metadata)) {
      const lower = key.toLowerCase();
      if (
        key !== 'annotations' &&
        (lower === 'annotations' || lower.startsWith('annotations.'))
      ) {
        delete metadata[key];
        changed = true;
      }
    }

    // Annotation names are matched without regard to case too, so every
    // spelling of the name is removed, not only the exact one.
    const annotations: Record<string, string> = {};
    const given = entity.metadata.annotations;
    for (const [name, value] of Object.entries(
      typeof given === 'object' && given !== null ? given : {},
    )) {
      const lower = name.toLowerCase();
      if (
        lower === ACCOUNT_ANNOTATION ||
        (account !== undefined &&
          (lower === ORPHAN_ANNOTATION ||
            (name === DOCS_ANNOTATION &&
              this.readsDocsElsewhere(value, given, location))))
      ) {
        changed = true;
      } else {
        annotations[name] = value;
      }
    }
    if (!changed) {
      return entity;
    }
    if (account === undefined) {
      return { ...entity, metadata: { ...metadata, annotations } };
    }
    annotations[ACCOUNT_ANNOTATION] = account;
    const stamped = { ...entity, metadata: { ...metadata, annotations } };
    return entityRef.startsWith('location:')
      ? this.withOwnTargets(stamped, entityRef, location, emit)
      : stamped;
  }

  /**
   * Whether the documentation builder, given the reference `docs` on an
   * entity read from the file at `location`, would read from anywhere but
   * the repository that file is in. The builder reads with the portal's
   * own access and shows the pages to whoever sees the entity, so a
   * registered file must not point it at somebody else's repository.
   *
   * A `url:` reference is read as it stands. A `dir:` reference is read
   * from the entity's source location when its file sets one, otherwise
   * from beside its file; `..` in it can lead out of the repository.
   */
  private readsDocsElsewhere(
    docs: unknown,
    annotations: Record<string, unknown> | undefined,
    location: LocationSpec,
  ): boolean {
    const reference = referenceIn(docs);
    if (!reference || (reference.type !== 'url' && reference.type !== 'dir')) {
      // Nothing the builder reads.
      return false;
    }
    let address = reference.target;
    if (reference.type === 'dir') {
      const source = referenceIn(annotations?.[SOURCE_ANNOTATION]) ?? location;
      if (source.type !== 'url') {
        // A directory of the machine the portal runs on.
        return true;
      }
      try {
        address = this.resolveUrl(reference.target, source.target);
      } catch {
        return true;
      }
    }
    const repository = repositoryOf(address);
    return (
      repository === undefined ||
      location.type !== 'url' ||
      repository !== repositoryOf(location.target)
    );
  }

  /**
   * A Location entry of a registered file, without the addresses it may
   * not read. Each refusal is reported as an error on the entry, which
   * also makes the catalog discard what the entry read this time.
   */
  private async withOwnTargets(
    entity: Entity,
    entityRef: string,
    location: LocationSpec,
    emit: CatalogProcessorEmit,
  ): Promise<Entity> {
    // The registered file itself was checked when it was registered.
    if (await this.stamps.isRegisteredFile(entityRef)) {
      return entity;
    }
    const spec: NonNullable<Entity['spec']> = entity.spec ?? {};
    const type = typeof spec.type === 'string' ? spec.type : location.type;
    const listed = [
      spec.target,
      ...(Array.isArray(spec.targets) ? spec.targets : []),
    ].filter((target): target is string => typeof target === 'string');

    const kept: string[] = [];
    for (const target of listed) {
      const refusal = await this.refusalOf(type, target, location, entityRef);
      if (refusal) {
        emit(processingResult.inputError(location, refusal));
      } else {
        kept.push(target);
      }
    }
    if (kept.length === listed.length) {
      return entity;
    }
    const narrowed: typeof spec = { ...spec, targets: kept };
    delete narrowed.target;
    return { ...entity, spec: narrowed };
  }

  /** Why a Location entry of a registered file may not read `target`, if so. */
  private async refusalOf(
    type: string,
    target: string,
    location: LocationSpec,
    entityRef: string,
  ): Promise<string | undefined> {
    if (type !== 'url') {
      return `A registered catalog file can only include files at a url, not ${type}:${target}`;
    }
    let address = target;
    if (location.type === 'url') {
      try {
        address = this.resolveUrl(target, location.target);
      } catch {
        // The catalog reads the address as written then.
      }
    }
    if (isWildcard(address)) {
      return `A registered catalog file cannot include files by wildcard (${address}); name each file`;
    }
    if (await this.stamps.heldElsewhere(address, entityRef)) {
      return `${address} is in the catalog already from somewhere else, so it is not included again`;
    }
    return undefined;
  }
}

/**
 * The accounts of registered files, kept in the catalog's own database so
 * that they can be read beside its `locations` table.
 */
export class LocationAccountsStore implements AccountStamps {
  constructor(private readonly knex: Knex) {}

  /**
   * Creates the table when it is not there yet. When the catalog already
   * has registered files at that moment, the portal is being upgraded from
   * a version without accounts: the same step notes that those files are
   * still to be handed over (see handOverEarlierFiles).
   */
  async initialise(): Promise<void> {
    if (await this.knex.schema.hasTable('location_accounts')) {
      return;
    }
    // On a new portal the catalog has not made its own tables yet.
    const upgraded =
      (await this.knex.schema.hasTable('locations')) &&
      Boolean(await this.knex('locations').where({ type: 'url' }).first('id'));
    await this.knex.transaction(async trx => {
      await trx.schema.createTable('location_accounts', table => {
        table.text('target').primary();
        table.text('account').notNullable();
      });
      if (upgraded) {
        await trx('location_accounts').insert(HAND_OVER);
      }
    });
  }

  /** Whether the files registered before accounts existed are still to be handed over. */
  async handOverPending(): Promise<boolean> {
    return Boolean(
      await this.knex('location_accounts').where(HAND_OVER).first('target'),
    );
  }

  /**
   * Files every registered file that has no account under `account` and
   * notes that the hand-over is done, in one step. Returns how many files
   * were filed, or undefined when there was no hand-over to do.
   */
  async handOver(account: string): Promise<number | undefined> {
    return this.knex.transaction(async trx => {
      const pending = await trx('location_accounts').where(HAND_OVER).delete();
      if (pending === 0) {
        return undefined;
      }
      const rows: Array<{ target: string }> = await trx('locations')
        .where({ type: 'url' })
        .whereNot({ target: HAND_OVER.target })
        .whereNotIn('target', trx('location_accounts').select('target'))
        .distinct('target');
      for (let from = 0; from < rows.length; from += 100) {
        await trx('location_accounts').insert(
          rows
            .slice(from, from + 100)
            .map(({ target }) => ({ target, account })),
        );
      }
      return rows.length;
    });
  }

  /**
   * What produced the entity, following the catalog's record up to where
   * each line starts: the entities of registered files (`files`), and
   * whether anything else (`operator`: a file named in the configuration,
   * an entity provider) is among the starts. `lost` when the lines are too
   * long to follow.
   */
  private async rootsOf(entityRef: string) {
    const files = new Set<string>();
    let operator = false;
    const seen = new Set([entityRef]);
    let frontier = [entityRef];
    for (let depth = 0; frontier.length > 0; depth++) {
      if (depth === 50) {
        return { files, operator, lost: true };
      }
      const rows: Array<{
        source_key: string | null;
        source_entity_ref: string | null;
        target_entity_ref: string;
      }> = await this.knex('refresh_state_references')
        .whereIn('target_entity_ref', frontier)
        .select('source_key', 'source_entity_ref', 'target_entity_ref');
      frontier = [];
      for (const row of rows) {
        if (row.source_key === REGISTERED_FILES) {
          files.add(row.target_entity_ref);
        } else if (row.source_key) {
          operator = true;
        } else if (row.source_entity_ref && !seen.has(row.source_entity_ref)) {
          seen.add(row.source_entity_ref);
          frontier.push(row.source_entity_ref);
        }
      }
    }
    return { files, operator, lost: false };
  }

  async stampFor(entityRef: string): Promise<string | undefined> {
    const roots = await this.rootsOf(entityRef);
    if (roots.lost) {
      return UNCLAIMED_ACCOUNT;
    }
    if (roots.operator) {
      // Entries the operator provides are shared, whoever else reads them.
      return undefined;
    }
    if (roots.files.size === 0) {
      // Nothing produces the entity (any more): it keeps the stamp this
      // processor gave it last, so that unregistering a file does not show
      // its entities to everyone while the catalog clears them away.
      const row = await this.knex('refresh_state')
        .where({ entity_ref: entityRef })
        .first('processed_entity');
      return accountIn(row?.processed_entity);
    }
    const rows: Array<{ target: string; account: string | null }> =
      await this.knex('locations')
        .leftJoin(
          'location_accounts',
          'location_accounts.target',
          'locations.target',
        )
        .where({ 'locations.type': 'url' })
        .whereIn('locations.location_entity_ref', [...roots.files])
        .select('locations.target as target', 'location_accounts.account');
    const accounts = new Set(
      rows.map(row =>
        row.target === HAND_OVER.target
          ? UNCLAIMED_ACCOUNT
          : row.account ?? UNCLAIMED_ACCOUNT,
      ),
    );
    // One account when every file it comes from is registered and that
    // account's; otherwise nobody's.
    const [account] = accounts;
    return accounts.size === 1 && rows.length === roots.files.size
      ? account
      : UNCLAIMED_ACCOUNT;
  }

  async isRegisteredFile(entityRef: string): Promise<boolean> {
    const row = await this.knex('locations')
      .where({ type: 'url', location_entity_ref: entityRef })
      .first('id');
    return Boolean(row);
  }

  async heldElsewhere(target: string, except?: string): Promise<boolean> {
    const held = this.knex('refresh_state')
      .join(
        'refresh_state_references',
        'refresh_state_references.target_entity_ref',
        'refresh_state.entity_ref',
      )
      .where('refresh_state.location_key', `url:${target}`);
    if (except !== undefined) {
      held.where(produced =>
        produced
          .whereNull('refresh_state_references.source_entity_ref')
          .orWhereNot('refresh_state_references.source_entity_ref', except),
      );
    }
    return Boolean(await held.first('refresh_state.entity_ref'));
  }

  /** Whether the file at `target` is registered. */
  async isRegistered(target: string): Promise<boolean> {
    const row = await this.knex('locations')
      .where({ type: 'url', target })
      .first('id');
    return Boolean(row);
  }

  /** The registered file with this id, as the catalog's API names it. */
  async locationById(id: string): Promise<RegisteredLocation | undefined> {
    // The id column is a uuid on some databases, where comparing it with
    // anything that is not one is an error; compared as text it is simply
    // not found.
    return this.knex('locations')
      .whereRaw('CAST(?? AS TEXT) = ?', ['id', id])
      .first('type', 'target');
  }

  /** The account of the registered file at `target`, when it has one. */
  async accountOf(target: string): Promise<string | undefined> {
    if (target === HAND_OVER.target) {
      return undefined;
    }
    const row = await this.knex('location_accounts')
      .where({ target })
      .first('account');
    return row?.account;
  }

  /** The addresses of the files registered under any of `accounts`. */
  async targetsOf(accounts: string[]): Promise<string[]> {
    if (accounts.length === 0) {
      return [];
    }
    const rows = await this.knex('location_accounts')
      .whereIn('account', accounts)
      .whereNot({ target: HAND_OVER.target })
      .select('target');
    return rows.map((row: { target: string }) => row.target);
  }

  /**
   * The addresses of the registered files that have no account: registered
   * by the backend itself, or not handed over yet.
   */
  async unclaimedTargets(): Promise<string[]> {
    const rows: Array<{ target: string }> = await this.knex('locations')
      .where({ type: 'url' })
      .whereNotIn(
        'target',
        this.knex('location_accounts')
          .whereNot({ target: HAND_OVER.target })
          .select('target'),
      )
      .distinct('target');
    return rows.map(row => row.target);
  }

  /**
   * Files the registered file at `target` under `account`, unless it is
   * already somebody's.
   */
  async claim(target: string, account: string): Promise<void> {
    if (target === HAND_OVER.target) {
      return;
    }
    await this.knex('location_accounts')
      .insert({ target, account })
      .onConflict('target')
      .ignore();
  }

  /**
   * Drops the account of `target` when no file is registered there any
   * more, so that whoever registers it next does not inherit it.
   */
  async forget(target: string): Promise<void> {
    if (target === HAND_OVER.target) {
      return;
    }
    await this.knex('location_accounts')
      .where({ target })
      .whereNotExists(
        this.knex('locations').where({ type: 'url', target }).select('id'),
      )
      .delete();
  }

  /** Follows a registered file whose address was changed from `from` to `to`. */
  async retarget(from: string, to: string | undefined): Promise<void> {
    if (from === to || from === HAND_OVER.target) {
      return;
    }
    if (to === HAND_OVER.target) {
      // Moved to the one address that cannot have an account.
      await this.knex('location_accounts').where({ target: from }).delete();
      return;
    }
    await this.knex.transaction(async trx => {
      const row = await trx('location_accounts')
        .where({ target: from })
        .first('account');
      await trx('location_accounts')
        .whereIn('target', to === undefined ? [from] : [from, to])
        .delete();
      if (row && to !== undefined) {
        await trx('location_accounts').insert({
          target: to,
          account: row.account,
        });
      }
    });
  }

  /**
   * Files everything registered under account `from` under `to`, and
   * returns the addresses that moved.
   */
  async moveAccount(from: string, to: string): Promise<string[]> {
    return this.knex.transaction(async trx => {
      const moved = () =>
        trx('location_accounts')
          .where({ account: from })
          .whereNot({ target: HAND_OVER.target });
      const rows: Array<{ target: string }> = await moved().select('target');
      await moved().update({ account: to });
      return rows.map(row => row.target);
    });
  }

  /** The entity the catalog keeps for the registered file at `target`. */
  async entityRefOf(target: string): Promise<string | undefined> {
    const row = await this.knex('locations')
      .where({ type: 'url', target })
      .first('location_entity_ref');
    return row?.location_entity_ref || undefined;
  }
}

/** The account this processor stamped on a processed entity, kept as JSON. */
function accountIn(processedEntity: unknown): string | undefined {
  if (typeof processedEntity !== 'string') {
    return undefined;
  }
  try {
    const entity: Partial<Entity> | null = JSON.parse(processedEntity);
    const account = entity?.metadata?.annotations?.[ACCOUNT_ANNOTATION];
    return typeof account === 'string' ? account : undefined;
  } catch {
    return undefined;
  }
}

/** How handing over the files registered before accounts existed went. */
export type HandOver =
  | { outcome: 'not-needed' }
  | { outcome: 'no-administrator' }
  | { outcome: 'handed-over'; files: number; account: string };

/**
 * Hands the files that were registered before accounts existed to whoever
 * runs the portal, once: to the first portal administrator who is a
 * person, filed under their organisation when they are in one. When the
 * portal has no such administrator, nothing changes (the files stay shown
 * to nobody but, in the list of registered files, portal administrators)
 * and the hand-over is still to do. Throws while the plugins that know the
 * administrators and organisations are starting.
 */
export async function handOverEarlierFiles(
  store: LocationAccountsStore,
  people: Pick<PortalAdmins, 'portalAdmins'> & Pick<Memberships, 'accountFor'>,
): Promise<HandOver> {
  if (!(await store.handOverPending())) {
    return { outcome: 'not-needed' };
  }
  const admin = (await people.portalAdmins()).find(ref =>
    ref.startsWith('user:'),
  );
  if (!admin) {
    return { outcome: 'no-administrator' };
  }
  const account = await people.accountFor(admin);
  const files = await store.handOver(account);
  return files === undefined
    ? { outcome: 'not-needed' }
    : { outcome: 'handed-over', files, account };
}

/** How long to wait before asking again while other plugins start. */
const HAND_OVER_RETRY_MS = 5000;

/** How long to wait before looking again for a first administrator. */
const HAND_OVER_WAIT_MS = 60_000;

/** What the registration recorder asks of this module. */
export interface LocationAccounts {
  store: LocationAccountsStore;
  /** Has the catalog read the file at `target` again now, not at its next turn. */
  refresh(target: string): Promise<void>;
}

let started: LocationAccounts | undefined;

/**
 * The accounts of registered files, for the registration recorder. Throws
 * until the catalog has started, so a request that arrives before then is
 * refused instead of being let through unchecked.
 */
export function locationAccounts(): LocationAccounts {
  if (!started) {
    throw new Error('The portal is still starting: the catalog is not ready');
  }
  return started;
}

export default createBackendModule({
  pluginId: 'catalog',
  moduleId: 'accounts',
  register(reg) {
    reg.registerInit({
      deps: {
        processing: catalogProcessingExtensionPoint,
        database: coreServices.database,
        logger: coreServices.logger,
        lifecycle: coreServices.lifecycle,
        auth: coreServices.auth,
        config: coreServices.rootConfig,
        catalog: catalogServiceRef,
      },
      async init({
        processing,
        database,
        logger,
        lifecycle,
        auth,
        config,
        catalog,
      }) {
        const store = new LocationAccountsStore(await database.getClient());
        await store.initialise();

        // Has the catalog read the file at `target` again now, so that its
        // entities get the account it has just been given.
        const refresh = async (target: string) => {
          try {
            const entityRef = await store.entityRefOf(target);
            if (entityRef) {
              await catalog.refreshEntity(entityRef, {
                credentials: await auth.getOwnServiceCredentials(),
              });
            }
          } catch (error) {
            // The catalog reads every file again at its own pace, so the
            // account is applied then.
            logger.debug(`Could not refresh the file at ${target}: ${error}`);
          }
        };

        // The hand-over of files registered before accounts existed. The
        // next time the catalog reads those files it stamps their entities.
        let stopped = false;
        let retry: NodeJS.Timeout | undefined;
        let waiting = false;
        const handOver = async () => {
          if (stopped) {
            return;
          }
          let again: number | undefined;
          try {
            const result = await handOverEarlierFiles(store, directory);
            if (result.outcome === 'handed-over') {
              logger.info(
                `Filed ${result.files} catalog files registered before accounts existed under ${result.account}`,
              );
            } else if (result.outcome === 'no-administrator') {
              again = HAND_OVER_WAIT_MS;
              if (!waiting) {
                waiting = true;
                logger.info(
                  'Catalog files registered before accounts existed are shown to nobody until the portal has an administrator; they are handed over within a minute of that',
                );
              }
            }
          } catch (error) {
            again = HAND_OVER_RETRY_MS;
            logger.debug(`Hand-over of earlier catalog files waits: ${error}`);
          }
          if (again !== undefined && !stopped) {
            retry = setTimeout(handOver, again);
          }
        };
        lifecycle.addStartupHook(() => {
          handOver();
        });
        lifecycle.addShutdownHook(() => {
          stopped = true;
          clearTimeout(retry);
        });

        const integrations = ScmIntegrations.fromConfig(config);
        processing.addProcessor(
          new AccountStampProcessor(store, (url, base) =>
            integrations.resolveUrl({ url, base }),
          ),
        );
        provide({
          async moveAccount(from, to) {
            for (const target of await store.moveAccount(from, to)) {
              await refresh(target);
            }
          },
        });

        started = { store, refresh };
      },
    });
  },
});
