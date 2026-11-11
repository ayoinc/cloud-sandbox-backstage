import { Hono } from 'hono';
import { callerRef, visibleTo } from './accounts';
import { requirePortalAdmin } from './admin';
import type { SqlFragment } from './catalog/filter';
import { handlePlainError, inputError, notFoundError } from './errors';
import { isRecord, readJson } from './json';
import type { AppEnv } from './types';

/**
 * Ownership management: which entities have an owner that no longer exists,
 * and the owners admins assigned to them instead. Same API as the Node
 * backend's ownership-management plugin, without its periodic orphan log:
 * nothing runs on a schedule here, and the page lists orphans on demand.
 *
 * For portal administrators only, and about the entities the administrator
 * may see: being one opens no other account's catalog.
 */

const MAX_BODY_BYTES = 16 * 1024;

// The kinds that have an owner, and the groups that can be one. Only the
// fields the page shows are taken out of each entity, by SQLite, so the
// Worker never parses whole entities.
const selectCatalog = (visible: SqlFragment) => `SELECT
  json_extract(e.final_entity, '$.kind') AS kind,
  json_extract(e.final_entity, '$.metadata.name') AS name,
  coalesce(json_extract(e.final_entity, '$.metadata.namespace'), 'default') AS namespace,
  json_extract(e.final_entity, '$.metadata.title') AS title,
  json_extract(e.final_entity, '$.metadata.description') AS description,
  json_extract(e.final_entity, '$.spec.owner') AS owner,
  json_extract(e.final_entity, '$.spec.profile.displayName') AS display_name
FROM final_entities e
WHERE e.entity_id IN (
  SELECT s.entity_id FROM search s
  WHERE s.key = 'kind' AND s.value IN ('component', 'api', 'resource', 'system', 'domain', 'group')
) AND (${visible.sql})
ORDER BY e.entity_ref`;

// An override is about an entity, and is listed and removed by those who
// may see that entity.
const ofVisibleEntity = (visible: SqlFragment) =>
  `EXISTS (SELECT 1 FROM final_entities e WHERE e.entity_ref = ownership_overrides.entity_ref AND (${visible.sql}))`;

const selectOverrides = (visible: SqlFragment) =>
  `SELECT entity_ref, new_owner, previous_owner, overridden_at, overridden_by FROM ownership_overrides WHERE ${ofVisibleEntity(
    visible,
  )} ORDER BY overridden_at DESC`;

interface CatalogRow {
  kind: string;
  name: string;
  namespace: string;
  title: string | null;
  description: string | null;
  owner: unknown;
  display_name: string | null;
}

interface OverrideRow {
  entity_ref: string;
  new_owner: string;
  previous_owner: string | null;
  overridden_at: string;
  overridden_by: string | null;
}

interface OwnedEntity {
  entityRef: string;
  kind: string;
  name: string;
  namespace: string;
  currentOwner: string;
  title?: string;
}

interface GroupInfo {
  name: string;
  displayName: string;
  description?: string;
  entityRef: string;
}

const toOverride = (row: OverrideRow) => ({
  entityRef: row.entity_ref,
  newOwner: row.new_owner,
  previousOwner: row.previous_owner,
  overriddenAt: row.overridden_at,
  overriddenBy: row.overridden_by,
});

/** An owner as a full lower-case ref: a bare name is a group in `default`. */
function normalizeOwnerRef(owner: string): string {
  const ref = owner.toLowerCase();
  if (!ref.includes(':')) {
    return `group:default/${ref}`;
  }
  if (!ref.includes('/')) {
    const [kind, name] = ref.split(':');
    return `${kind}:default/${name}`;
  }
  return ref;
}

/**
 * Every ownable entity `viewer` may see with its owner in effect, and every
 * group they may see by lower-case ref. One round trip to D1, whatever the
 * size of the catalog.
 */
async function loadOwnership(db: D1Database, viewer: string) {
  const visible = visibleTo(viewer);
  const [catalog, stored] = (await db.batch([
    db.prepare(selectCatalog(visible)).bind(...visible.params),
    db.prepare(selectOverrides(visible)).bind(...visible.params),
  ])) as [D1Result<CatalogRow>, D1Result<OverrideRow>];
  const overrides = new Map(
    stored.results.map(row => [row.entity_ref, row.new_owner]),
  );
  const groups = new Map<string, GroupInfo>();
  const entities: OwnedEntity[] = [];
  for (const row of catalog.results) {
    const entityRef = `${row.kind.toLowerCase()}:${row.namespace}/${row.name}`;
    if (row.kind.toLowerCase() === 'group') {
      groups.set(entityRef.toLowerCase(), {
        name: row.name,
        displayName: row.display_name || row.name,
        description: row.description ?? undefined,
        entityRef,
      });
    } else if (typeof row.owner === 'string' && row.owner) {
      entities.push({
        entityRef,
        kind: row.kind,
        name: row.name,
        namespace: row.namespace,
        currentOwner: overrides.get(entityRef.toLowerCase()) ?? row.owner,
        title: row.title ?? undefined,
      });
    }
  }
  // An owner exists when it is a group in the catalog. Users are taken at
  // their word: people who only sign in are not all in the catalog.
  const ownerExists = (entity: OwnedEntity) => {
    const owner = normalizeOwnerRef(entity.currentOwner);
    return groups.has(owner) || owner.startsWith('user:');
  };
  return { entities, groups, ownerExists };
}

export const ownershipRoutes = new Hono<AppEnv>();

ownershipRoutes.onError(handlePlainError);

ownershipRoutes.use('*', async (c, next) => {
  await requirePortalAdmin(c);
  await next();
});

ownershipRoutes.get('/orphans', async c => {
  const { entities, ownerExists } = await loadOwnership(c.env.DB, callerRef(c));
  const orphans = entities.filter(entity => !ownerExists(entity));
  return c.json({ count: orphans.length, orphans });
});

ownershipRoutes.get('/groups', async c => {
  const { groups } = await loadOwnership(c.env.DB, callerRef(c));
  const sorted = [...groups.values()].sort((a, b) =>
    a.displayName.localeCompare(b.displayName),
  );
  return c.json({ count: sorted.length, groups: sorted });
});

ownershipRoutes.get('/entities', async c => {
  const { entities, ownerExists } = await loadOwnership(c.env.DB, callerRef(c));
  return c.json({
    count: entities.length,
    entities: entities.map(entity => ({
      ...entity,
      ownerExists: ownerExists(entity),
    })),
  });
});

ownershipRoutes.get('/overrides', async c => {
  const visible = visibleTo(callerRef(c));
  const { results } = await c.env.DB.prepare(selectOverrides(visible))
    .bind(...visible.params)
    .all<OverrideRow>();
  return c.json({ count: results.length, overrides: results.map(toOverride) });
});

ownershipRoutes.post('/reassign', async c => {
  const admin = c.get('user').userEntityRef;
  const body = await readJson(c, MAX_BODY_BYTES);
  const { entityRef, newOwner } = isRecord(body) ? body : {};
  if (
    typeof entityRef !== 'string' ||
    typeof newOwner !== 'string' ||
    !entityRef ||
    !newOwner
  ) {
    throw inputError('entityRef and newOwner are required');
  }
  const ref = entityRef.toLowerCase();
  const owner = normalizeOwnerRef(newOwner);
  // A group or an entity the administrator may not see is not found, as one
  // that does not exist.
  const visible = visibleTo(callerRef(c));
  const [group, entity, override] = await c.env.DB.batch<
    Record<string, unknown>
  >([
    c.env.DB.prepare(
      `SELECT 1 AS found FROM final_entities e WHERE e.entity_ref = ? AND e.entity_ref LIKE 'group:%' AND (${visible.sql})`,
    ).bind(owner, ...visible.params),
    c.env.DB.prepare(
      `SELECT json_extract(e.final_entity, '$.spec.owner') AS owner FROM final_entities e WHERE e.entity_ref = ? AND (${visible.sql})`,
    ).bind(ref, ...visible.params),
    c.env.DB.prepare(
      'SELECT new_owner FROM ownership_overrides WHERE entity_ref = ?',
    ).bind(ref),
  ]);
  if (!group.results.length) {
    throw inputError(`Owner group '${newOwner}' not found`);
  }
  if (!entity.results.length) {
    throw notFoundError(`Entity '${entityRef}' not found`);
  }
  const previousOwner = String(
    override.results[0]?.new_owner ?? entity.results[0].owner ?? 'unknown',
  );
  const overriddenAt = new Date().toISOString();
  await c.env.DB.prepare(
    'INSERT INTO ownership_overrides (entity_ref, new_owner, previous_owner, overridden_at, overridden_by) VALUES (?, ?, ?, ?, ?) ON CONFLICT (entity_ref) DO UPDATE SET new_owner = excluded.new_owner, previous_owner = excluded.previous_owner, overridden_at = excluded.overridden_at, overridden_by = excluded.overridden_by',
  )
    .bind(ref, owner, previousOwner, overriddenAt, admin)
    .run();
  return c.json({
    success: true,
    message: `Ownership of ${entityRef} has been reassigned to ${owner}`,
    entityRef,
    previousOwner,
    newOwner: owner,
    overriddenBy: admin,
    overriddenAt,
  });
});

// The entity ref has a slash in it, so it is a query parameter, not a path.
ownershipRoutes.delete('/overrides', async c => {
  const entityRef = c.req.query('entityRef');
  if (!entityRef) {
    throw inputError('entityRef query parameter is required');
  }
  const visible = visibleTo(callerRef(c));
  const removed = await c.env.DB.prepare(
    `DELETE FROM ownership_overrides WHERE entity_ref = ? AND ${ofVisibleEntity(
      visible,
    )} RETURNING entity_ref, new_owner, previous_owner, overridden_at, overridden_by`,
  )
    .bind(entityRef.toLowerCase(), ...visible.params)
    .first<OverrideRow>();
  if (!removed) {
    throw notFoundError('Override not found');
  }
  return c.json({
    success: true,
    message: `Ownership override removed for ${entityRef}`,
    entityRef,
    previousOverride: toOverride(removed),
  });
});
