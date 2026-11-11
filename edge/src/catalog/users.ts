import { fromRegisteredFile } from '../accounts';
import type { Session } from '../auth';
import type { SqlFragment } from './filter';

/**
 * People who have signed in, as catalog User entities.
 *
 * Nobody lists the portal's users in a catalog file: they sign in through
 * GitHub or Google. Each sign-in is recorded in `signed_in_users` as a
 * finished User entity with its search rows and search document, and copied
 * from there into the catalog tables, so every catalog and search query
 * finds the user like any other entity. A catalog sync replaces those
 * tables, and copies the users back in the same transaction.
 *
 * A user that a file the operator configured also defines is not copied: the
 * catalog's entity is the one served. A file registered through the portal
 * cannot do that. Anyone may register one and name a User in it after a real
 * person, so such an entity gives way to the person's own, at sign-in and at
 * every catalog sync.
 */

/**
 * Condition on a `final_entities` row `f`: it comes from a file registered
 * through the portal, whether the file still is or was unregistered since
 * (edge/src/accounts.ts).
 */
const FROM_A_REGISTERED_FILE = fromRegisteredFile('f');

/**
 * Condition on a `final_entities` row `f` beside a `signed_in_users` row
 * `u`: the entity stands where the person belongs. It has their ref, is not
 * their copy, and comes from a registered file.
 */
const STANDS_IN = `f.entity_ref = u.entity_ref AND f.entity_id <> u.entity_id AND ${FROM_A_REGISTERED_FILE}`;

/** The annotation Backstage uses for the account behind a user, per provider. */
const ACCOUNT_ANNOTATION: Record<string, string> = {
  github: 'github.com/user-login',
  google: 'google.com/email',
};

// Limits and exclusions of the catalog's search table, as in
// `buildEntitySearch` of `@backstage/plugin-catalog-backend`.
const MAX_KEY_LENGTH = 200;
const MAX_VALUE_LENGTH = 200;
const SPECIAL_KEYS = [
  'attachments',
  'relations',
  'status',
  'metadata.name',
  'metadata.namespace',
  'metadata.uid',
  'metadata.etag',
];

const encoder = new TextEncoder();

interface UserEntity {
  apiVersion: string;
  kind: string;
  metadata: {
    namespace: string;
    name: string;
    annotations: Record<string, string>;
    uid: string;
    etag?: string;
  };
  spec: {
    profile: { displayName?: string; email?: string; picture?: string };
    memberOf: string[];
  };
  relations: never[];
}

type SearchRow = [key: string, value: string | null, original: string | null];

async function userEntity(
  session: Session,
  namespace: string,
  name: string,
  uid: string,
): Promise<UserEntity> {
  const { displayName, email, picture } = session.profile;
  const account = ACCOUNT_ANNOTATION[session.provider];
  // There is no file behind the entity; the location says where it came from.
  const location = `sign-in:${session.provider}`;
  const entity: UserEntity = {
    apiVersion: 'backstage.io/v1alpha1',
    kind: 'User',
    metadata: {
      namespace,
      name,
      annotations: {
        'backstage.io/managed-by-location': location,
        'backstage.io/managed-by-origin-location': location,
        ...(account && { [account]: session.id }),
      },
      uid,
    },
    spec: { profile: { displayName, email, picture }, memberOf: [] },
    relations: [],
  };
  const hash = await crypto.subtle.digest(
    'SHA-1',
    encoder.encode(JSON.stringify(entity)),
  );
  entity.metadata.etag = Array.from(new Uint8Array(hash), byte =>
    byte.toString(16).padStart(2, '0'),
  ).join('');
  return entity;
}

/**
 * The entity's rows for the catalog `search` table. Port of
 * `buildEntitySearch` in `@backstage/plugin-catalog-backend`, without the
 * relation rows: these users have no relations.
 */
function searchRows(entity: UserEntity): SearchRow[] {
  const raw: { key: string; value: unknown }[] = [];
  const seenPaths = new Set<string>();
  const visit = (path: string, current: unknown) => {
    if (SPECIAL_KEYS.includes(path)) {
      return;
    }
    if (
      current === undefined ||
      current === null ||
      ['string', 'number', 'boolean'].includes(typeof current)
    ) {
      raw.push({ key: path, value: current });
      return;
    }
    if (typeof current !== 'object') {
      return;
    }
    if (Array.isArray(current)) {
      for (const item of current) {
        visit(path, item);
        if (typeof item === 'string') {
          const itemPath = `${path}.${item}`;
          if (!seenPaths.has(itemPath.toLowerCase())) {
            seenPaths.add(itemPath.toLowerCase());
            raw.push({ key: itemPath, value: true });
          }
        }
      }
      return;
    }
    for (const [key, value] of Object.entries(current)) {
      visit(path ? `${path}.${key}` : key, value);
    }
  };
  visit('', entity);
  raw.push(
    { key: 'metadata.name', value: entity.metadata.name },
    { key: 'metadata.namespace', value: entity.metadata.namespace },
    { key: 'metadata.uid', value: entity.metadata.uid },
  );

  // One row per key and value; the first one seen is kept.
  const rows = new Map<string, SearchRow>();
  for (const { key: rawKey, value } of raw) {
    const key = rawKey.toLowerCase();
    if (key.length > MAX_KEY_LENGTH) {
      continue;
    }
    const original =
      value === undefined || value === null ? null : String(value);
    const row: SearchRow =
      original === null || original.length > MAX_VALUE_LENGTH
        ? [key, null, null]
        : [key, original.toLowerCase(), original];
    const id = JSON.stringify(row.slice(0, 2));
    if (!rows.has(id)) {
      rows.set(id, row);
    }
  }
  return [...rows.values()];
}

/** The search document Backstage's catalog collator builds for a user. */
function searchDocument(entity: UserEntity) {
  const { namespace, name } = entity.metadata;
  const { displayName, email } = entity.spec.profile;
  return {
    title: name,
    text: [displayName, email].filter(Boolean).join(' : '),
    location: `/catalog/${encodeURIComponent(
      namespace,
    )}/user/${encodeURIComponent(name)}`,
    componentType: 'other',
    type: 'other',
    namespace,
    kind: entity.kind,
    lifecycle: '',
    owner: '',
  };
}

/**
 * Statements that copy signed-in users into the catalog tables: the users
 * `where` selects (table alias `u`). An entity from a registered file that
 * stands in for one of them is removed first, with its search rows, its
 * search document and the link to the file it came from. A user whose ref
 * an entity from one of the operator's files has is not copied.
 *
 * They belong in one batch with whatever removed those users' earlier
 * copies; run twice, they would add the search rows twice.
 */
export function copySignedInUsers(
  db: D1Database,
  where: SqlFragment,
): D1PreparedStatement[] {
  const standIns = (columns: string) =>
    `SELECT ${columns} FROM signed_in_users u JOIN final_entities f ON ${STANDS_IN} WHERE (${where.sql})`;
  const copied =
    'EXISTS (SELECT 1 FROM final_entities f WHERE f.entity_id = u.entity_id)';
  return [
    // The catalog spells the name in a document's address as the file does.
    `DELETE FROM search_documents WHERE type = 'software-catalog' AND lower(json_extract(document, '$.location')) IN (${standIns(
      "lower(json_extract(u.search_document, '$.location'))",
    )})`,
    `DELETE FROM search WHERE entity_id IN (${standIns('f.entity_id')})`,
    `DELETE FROM refresh_state_references WHERE target_entity_ref IN (${standIns(
      'f.entity_ref',
    )})`,
    `DELETE FROM final_entities WHERE entity_id IN (${standIns(
      'f.entity_id',
    )})`,
    `INSERT INTO final_entities (entity_id, entity_ref, final_entity) SELECT u.entity_id, u.entity_ref, u.final_entity FROM signed_in_users u WHERE NOT EXISTS (SELECT 1 FROM final_entities f WHERE f.entity_ref = u.entity_ref) AND (${where.sql})`,
    `INSERT INTO search (entity_id, key, value, original_value) SELECT u.entity_id, json_extract(r.value, '$[0]'), json_extract(r.value, '$[1]'), json_extract(r.value, '$[2]') FROM signed_in_users u, json_each(u.search_rows) r WHERE ${copied} AND (${where.sql})`,
    `INSERT INTO search_documents (title, text, type, document) SELECT json_extract(u.search_document, '$.title'), json_extract(u.search_document, '$.text'), 'software-catalog', u.search_document FROM signed_in_users u WHERE ${copied} AND (${where.sql})`,
  ].map(sql => db.prepare(sql).bind(...where.params));
}

async function saveSignedInUser(
  db: D1Database,
  session: Session,
): Promise<void> {
  const entityRef = session.sub.toLowerCase();
  const [, namespace, name] = /^user:([^:/]+)\/([^:/]+)$/.exec(entityRef) ?? [];
  if (!namespace || !name) {
    return;
  }
  // `settled` is false when a catalog sync by an earlier version of the
  // Worker removed the user's copy, and when an entity from a registered
  // file stands in for the user; saving again puts the copy in.
  const stored = await db
    .prepare(
      `SELECT u.entity_id, u.final_entity, EXISTS (SELECT 1 FROM final_entities f WHERE f.entity_ref = u.entity_ref AND NOT (${STANDS_IN})) AS settled FROM signed_in_users u WHERE u.entity_ref = ?`,
    )
    .bind(entityRef)
    .first<{ entity_id: string; final_entity: string; settled: number }>();
  const entityId = stored?.entity_id ?? crypto.randomUUID();
  const entity = await userEntity(session, namespace, name, entityId);
  const finalEntity = JSON.stringify(entity);
  if (stored?.final_entity === finalEntity && stored.settled) {
    return;
  }
  const document = searchDocument(entity);
  await db.batch([
    db
      .prepare(
        'INSERT INTO signed_in_users (entity_ref, entity_id, final_entity, search_rows, search_document, updated_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT (entity_ref) DO UPDATE SET final_entity = excluded.final_entity, search_rows = excluded.search_rows, search_document = excluded.search_document, updated_at = excluded.updated_at',
      )
      .bind(
        entityRef,
        entityId,
        finalEntity,
        JSON.stringify(searchRows(entity)),
        JSON.stringify(document),
        new Date().toISOString(),
      ),
    // The earlier copy, if there is one. Without a copy the catalog defines
    // the user itself, and the search document at this address is its own:
    // it stays when the operator's file defines the user, and goes with the
    // entity below when a registered file does.
    db
      .prepare(
        "DELETE FROM search_documents WHERE type = 'software-catalog' AND json_extract(document, '$.location') = ? AND EXISTS (SELECT 1 FROM final_entities WHERE entity_id = ?)",
      )
      .bind(document.location, entityId),
    db.prepare('DELETE FROM search WHERE entity_id = ?').bind(entityId),
    db.prepare('DELETE FROM final_entities WHERE entity_id = ?').bind(entityId),
    ...copySignedInUsers(db, { sql: 'u.entity_ref = ?', params: [entityRef] }),
  ]);
}

/**
 * Records who a session belongs to as a catalog User entity, with the name,
 * email and picture the provider gave. Writes only when something changed,
 * so it is cheap to call on every session refresh.
 *
 * A failure is logged and not thrown: the entity is what makes the user
 * show up by name, and nobody should be locked out for lack of it.
 */
export async function recordSignIn(
  db: D1Database,
  session: Session,
): Promise<void> {
  try {
    await saveSignedInUser(db, session);
  } catch (error) {
    console.error(
      JSON.stringify({
        message: 'Could not record the signed-in user in the catalog',
        user: session.sub,
        error: error instanceof Error ? error.message : String(error),
      }),
    );
  }
}

/**
 * The columns that name a user. With `key`, the column is part of the
 * table's key, so a row cannot move where the new name already holds one.
 * Such a row is removed instead: left behind, it would be handed to whoever
 * next signs in under the old name.
 */
const NAMED_IN: { table: string; column: string; key?: true }[] = [
  { table: 'user_settings', column: 'user_entity_ref', key: true },
  { table: 'organisation_members', column: 'user_ref', key: true },
  { table: 'organisation_members', column: 'added_by' },
  { table: 'organisation_invitations', column: 'user_ref', key: true },
  { table: 'organisation_invitations', column: 'invited_by' },
  { table: 'tasks', column: 'created_by' },
  { table: 'branding_admins', column: 'entity_ref', key: true },
  { table: 'branding_admins', column: 'added_by' },
  { table: 'ownership_overrides', column: 'overridden_by' },
  { table: 'locations', column: 'account' },
];

/**
 * Whether `signed_in_users` still holds user ?1 as the Google account ?2.
 * A GitHub user of the same name is recorded without a Google address, so
 * nothing of theirs is ever moved.
 */
const IS_THE_GOOGLE_USER = `EXISTS (SELECT 1 FROM signed_in_users WHERE entity_ref = ?1 AND json_extract(final_entity, '$.metadata.annotations."google.com/email"') = ?2)`;

/**
 * Google sign-in once named a person by the part of their address before
 * the @ (`from`), and now names them by the whole address (`to`). When the
 * person last recorded under the old name is this Google account, what they
 * had there is passed on to the new name, and the old user is removed from
 * the catalog; `recordSignIn` then records the new one.
 *
 * Not to be called where a GitHub account may sign in under the old name:
 * the two shared it, and the last of them to sign in would take everything.
 *
 * One batch, so one transaction, and every statement in it asks again
 * whether the old name is still theirs: called twice, or at the same moment
 * as a GitHub user of that name signs in, it moves things once or not at
 * all. A failure is logged and not thrown; the next refresh tries again.
 */
export async function carryOver(
  db: D1Database,
  { email, from, to }: { email: string; from: string; to: string },
): Promise<void> {
  if (from === to) {
    return;
  }
  try {
    const old = await db
      .prepare(
        `SELECT entity_id, json_extract(search_document, '$.location') AS location FROM signed_in_users WHERE entity_ref = ?1 AND ${IS_THE_GOOGLE_USER}`,
      )
      .bind(from, email)
      .first<{ entity_id: string; location: string }>();
    if (!old) {
      return;
    }
    const moves = NAMED_IN.flatMap(({ table, column, key }) => [
      // A row the new name already holds stays as it is: see NAMED_IN.
      db
        .prepare(
          `UPDATE${
            key ? ' OR IGNORE' : ''
          } ${table} SET ${column} = ?3 WHERE ${column} = ?1 AND ${IS_THE_GOOGLE_USER}`,
        )
        .bind(from, email, to),
      ...(key
        ? [
            db
              .prepare(
                `DELETE FROM ${table} WHERE ${column} = ?1 AND ${IS_THE_GOOGLE_USER}`,
              )
              .bind(from, email),
          ]
        : []),
    ]);
    await db.batch([
      ...moves,
      // The old user's copy in the catalog, as saveSignedInUser removes it.
      // Without a copy the catalog defines that user itself.
      db
        .prepare(
          `DELETE FROM search_documents WHERE type = 'software-catalog' AND json_extract(document, '$.location') = ?3 AND EXISTS (SELECT 1 FROM final_entities WHERE entity_id = ?4) AND ${IS_THE_GOOGLE_USER}`,
        )
        .bind(from, email, old.location, old.entity_id),
      ...['search', 'final_entities'].map(table =>
        db
          .prepare(
            `DELETE FROM ${table} WHERE entity_id = ?3 AND ${IS_THE_GOOGLE_USER}`,
          )
          .bind(from, email, old.entity_id),
      ),
      // Last: it is what the statements before it ask about.
      db
        .prepare(
          `DELETE FROM signed_in_users WHERE entity_ref = ?1 AND json_extract(final_entity, '$.metadata.annotations."google.com/email"') = ?2`,
        )
        .bind(from, email),
    ]);
  } catch (error) {
    console.error(
      JSON.stringify({
        message: "Could not carry a user's things over to their new name",
        from,
        to,
        error: error instanceof Error ? error.message : String(error),
      }),
    );
  }
}
