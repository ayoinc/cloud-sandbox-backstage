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
 * A user that a catalog file also defines is not copied: the catalog's
 * entity is the one served.
 */

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
 * `where` selects (table alias `u`) whose entity ref no catalog entity has.
 * They belong in one batch with whatever removed those users' earlier
 * copies; run twice, they would add the search rows twice.
 */
export function copySignedInUsers(
  db: D1Database,
  where: SqlFragment,
): D1PreparedStatement[] {
  const copied =
    'EXISTS (SELECT 1 FROM final_entities f WHERE f.entity_id = u.entity_id)';
  return [
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
  // `listed` is false when a catalog sync by an earlier version of the
  // Worker removed the user's copy; saving again puts it back.
  const stored = await db
    .prepare(
      'SELECT u.entity_id, u.final_entity, EXISTS (SELECT 1 FROM final_entities f WHERE f.entity_ref = u.entity_ref) AS listed FROM signed_in_users u WHERE u.entity_ref = ?',
    )
    .bind(entityRef)
    .first<{ entity_id: string; final_entity: string; listed: number }>();
  const entityId = stored?.entity_id ?? crypto.randomUUID();
  const entity = await userEntity(session, namespace, name, entityId);
  const finalEntity = JSON.stringify(entity);
  if (stored?.final_entity === finalEntity && stored.listed) {
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
    // the user itself, and the search document at this address is its own.
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
