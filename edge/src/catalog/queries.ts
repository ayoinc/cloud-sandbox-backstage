import { refShownTo, servedTo, visibleTo } from '../accounts';
import { inJsonArray, predicateToSql, type SqlFragment } from './filter';

/**
 * Catalog read queries against D1. Ports of `DefaultEntitiesCatalog` in
 * `@backstage/plugin-catalog-backend`, kept to the same SQL shape so results
 * and paging match the Backstage backend.
 *
 * Entities are returned as JSON text and are never parsed here. What is
 * sent is the stored entity less its relations to entities the viewer may
 * not see (`servedTo` in accounts.ts).
 *
 * Every query takes its `viewer`, a lower-case user ref, and answers with
 * the entities that user may see (accounts.ts): to the viewer the others do
 * not exist, in lists, counts and facets alike.
 */

export type Order = 'asc' | 'desc';

export interface OrderField {
  field: string;
  order?: Order;
}

export interface FullTextFilter {
  term?: string;
  fields?: string[];
}

/** Paging state. Sent to clients base64-encoded and returned by them as-is. */
export interface QueryCursor {
  /** Predicate from `filter=` query strings. */
  filter?: unknown;
  /** Predicate from a POST body. Clients look for this key to choose POST. */
  query?: unknown;
  orderFields: OrderField[];
  fullTextFilter?: FullTextFilter;
  orderFieldValues?: (string | null)[];
  firstSortFieldValues?: (string | null)[];
  isPrevious: boolean;
  totalItems?: number;
}

export interface QueryEntitiesRequest {
  cursor: QueryCursor;
  /** True for a first page, false when following a cursor. */
  isInitial: boolean;
  limit?: number;
  offset?: number;
  totalItems: 'include' | 'exclude';
}

export interface QueryEntitiesResult {
  items: string[];
  totalItems: number;
  nextCursor?: QueryCursor;
  prevCursor?: QueryCursor;
}

const DEFAULT_QUERY_LIMIT = 200;

const direction = (order: Order | undefined) =>
  order === 'desc' ? 'DESC' : 'ASC';

interface EntityRow {
  entity_id: string;
  final_entity: string;
  value?: string | null;
}

/**
 * A search row under a `relations.<type>` key holds the ref of another
 * entity. Where a statement reads such rows by key, to sort by, look
 * through or count, this is the condition that leaves out those of
 * entities `viewer` may not see; `undefined` when no key is a relation's.
 */
function relationRowsShown(
  viewer: string,
  keys: string[],
  alias: string,
): SqlFragment | undefined {
  if (!keys.some(key => key.startsWith('relations.'))) {
    return undefined;
  }
  const shown = refShownTo(viewer, `${alias}.value`);
  return {
    sql: `(substr(${alias}.key, 1, 10) <> 'relations.' OR ${shown.sql})`,
    params: shown.params,
  };
}

/**
 * Filter, POST query and full-text conditions for an entity aliased `e`,
 * after the one that leaves out what `viewer` may not see.
 */
function conditions(
  viewer: string,
  cursor: QueryCursor,
  sortKey: string | undefined,
  sortRowInScope: boolean,
): SqlFragment[] {
  const result: SqlFragment[] = [visibleTo(viewer)];
  if (cursor.filter !== undefined) {
    result.push(predicateToSql(cursor.filter, viewer));
  }
  if (cursor.query !== undefined) {
    result.push(predicateToSql(cursor.query, viewer));
  }
  const term = cursor.fullTextFilter?.term?.trim().toLowerCase();
  if (term) {
    const fields = (
      cursor.fullTextFilter?.fields ?? [sortKey ?? 'metadata.uid']
    ).map(field => field.toLowerCase());
    // instr() rather than LIKE: D1 caps LIKE patterns at 50 bytes.
    if (sortRowInScope && fields.length === 1 && fields[0] === sortKey) {
      result.push({ sql: 'instr(o.value, ?) > 0', params: [term] });
    } else {
      const shown = relationRowsShown(viewer, fields, 's');
      result.push({
        sql: `e.entity_id IN (SELECT s.entity_id FROM search s WHERE ${inJsonArray(
          's.key',
        )} AND instr(s.value, ?) > 0${shown ? ` AND ${shown.sql}` : ''})`,
        params: [JSON.stringify(fields), term, ...(shown?.params ?? [])],
      });
    }
  }
  return result;
}

function append(sql: string, params: unknown[], parts: SqlFragment[]): string {
  let result = sql;
  for (const part of parts) {
    result += ` AND (${part.sql})`;
    params.push(...part.params);
  }
  return result;
}

/** Cursor-paged entity query: `/entities/by-query`. */
export async function queryEntities(
  db: D1Database,
  viewer: string,
  request: QueryEntitiesRequest,
): Promise<QueryEntitiesResult> {
  const { cursor } = request;
  const limit = request.limit ?? DEFAULT_QUERY_LIMIT;
  const sortField = cursor.orderFields.at(0);
  const sortKey = sortField?.field.toLowerCase();
  const backwards = cursor.isPrevious;
  const descending = sortField?.order === 'desc';

  // The rows a sort by a relation runs over are those of entities the
  // viewer may see: the others would show in the order, and in cursors.
  const sortRowShown = relationRowsShown(viewer, sortKey ? [sortKey] : [], 'o');
  const params: unknown[] = [];
  let sql = sortKey
    ? 'WITH filtered AS (SELECT e.entity_id AS entity_id, e.final_entity AS final_entity, o.value AS value FROM search o JOIN final_entities e ON e.entity_id = o.entity_id WHERE o.key = ? AND o.value IS NOT NULL'
    : 'WITH filtered AS (SELECT e.entity_id AS entity_id, e.final_entity AS final_entity FROM final_entities e WHERE 1 = 1';
  if (sortKey) {
    params.push(sortKey);
  }
  sql = append(sql, params, [
    ...(sortRowShown ? [sortRowShown] : []),
    ...conditions(viewer, cursor, sortKey, Boolean(sortKey)),
  ]);
  // The page is cut first, and only its entities are made ready to send.
  const served = servedTo(viewer, 'page');
  sql += `) SELECT page.entity_id AS entity_id, ${
    sortKey ? 'page.value AS value, ' : ''
  }${served.sql} AS final_entity FROM (SELECT * FROM filtered`;
  params.push(...served.params);

  const position = cursor.orderFieldValues;
  if (position?.length === 2) {
    const op = backwards !== descending ? '<' : '>';
    sql += ` WHERE (value ${op} ? OR (value = ? AND entity_id ${op} ?))`;
    params.push(position[0], position[0], position[1]);
  } else if (position?.length === 1) {
    sql += ` WHERE entity_id ${backwards ? '<' : '>'} ?`;
    params.push(position[0]);
  }

  const order = direction(
    backwards ? (descending ? 'asc' : 'desc') : sortField?.order,
  );
  const orderBy = (alias: string) =>
    ` ORDER BY ${
      sortKey ? `${alias}value ${order}, ` : ''
    }${alias}entity_id ${order}`;
  sql += `${orderBy('')} LIMIT ?`;
  params.push(backwards ? limit : limit + 1);
  if (request.isInitial && request.offset !== undefined) {
    sql += ' OFFSET ?';
    params.push(request.offset);
  }
  sql += `) page${orderBy('page.')}`;

  const countTotal =
    cursor.totalItems === undefined && request.totalItems !== 'exclude';
  const statements: D1PreparedStatement[] = [];
  if (limit > 0) {
    statements.push(db.prepare(sql).bind(...params));
  }
  if (countTotal) {
    const countParams: unknown[] = [];
    let countSql = 'SELECT count(*) AS count FROM final_entities e WHERE 1 = 1';
    if (sortKey) {
      countSql += ` AND EXISTS (SELECT 1 FROM search o WHERE o.entity_id = e.entity_id AND o.key = ? AND o.value IS NOT NULL${
        sortRowShown ? ` AND ${sortRowShown.sql}` : ''
      })`;
      countParams.push(sortKey, ...(sortRowShown?.params ?? []));
    }
    countSql = append(
      countSql,
      countParams,
      conditions(viewer, cursor, sortKey, false),
    );
    statements.push(db.prepare(countSql).bind(...countParams));
  }
  // One batch is one D1 round trip, and counts as one query against plan limits.
  const results = statements.length
    ? await db.batch<Record<string, unknown>>(statements)
    : [];

  const rows = (limit > 0 ? results[0].results : []) as unknown as EntityRow[];
  const totalItems =
    cursor.totalItems ??
    (countTotal ? Number(results.at(-1)?.results[0]?.count ?? 0) : 0);

  if (backwards) {
    rows.reverse();
  }
  const hasMore = limit > 0 && (backwards || rows.length > limit);
  if (rows.length > limit) {
    rows.length -= 1;
  }

  const sortValues = (row: EntityRow | undefined): (string | null)[] =>
    sortField
      ? [row?.value ?? null, row?.entity_id ?? null]
      : [row?.entity_id ?? null];
  const first = rows.at(0);
  const firstSortFieldValues = cursor.firstSortFieldValues ?? sortValues(first);
  const movedFromStart =
    cursor.firstSortFieldValues !== undefined &&
    rows.length > 0 &&
    JSON.stringify(sortValues(first)) !==
      JSON.stringify(cursor.firstSortFieldValues);

  return {
    items: rows.map(row => row.final_entity),
    totalItems,
    nextCursor: hasMore
      ? {
          ...cursor,
          orderFieldValues: sortValues(rows.at(-1)),
          firstSortFieldValues,
          isPrevious: false,
          totalItems,
        }
      : undefined,
    prevCursor: movedFromStart
      ? {
          ...cursor,
          orderFieldValues: sortValues(first),
          isPrevious: true,
          totalItems,
        }
      : undefined,
  };
}

export interface ListEntitiesRequest {
  filter?: unknown;
  order: OrderField[];
  limit?: number;
  offset?: number;
}

/** Offset-paged entity list: `/entities`. Entities missing an order field sort last. */
export async function listEntities(
  db: D1Database,
  viewer: string,
  request: ListEntitiesRequest,
): Promise<{ items: string[]; hasNextPage: boolean }> {
  const { order, limit, offset } = request;
  const params: unknown[] = [];
  // The page is cut first, and only its entities are made ready to send.
  const served = servedTo(viewer, 'page');
  let sql = `SELECT ${
    served.sql
  } AS final_entity FROM (SELECT e.final_entity AS final_entity, e.entity_id AS entity_id, e.entity_ref AS entity_ref${order
    .map((_, index) => `, o${index}.value AS value${index}`)
    .join('')} FROM final_entities e`;
  params.push(...served.params);
  order.forEach(({ field }, index) => {
    const key = field.toLowerCase();
    const shown = relationRowsShown(viewer, [key], `o${index}`);
    sql += ` LEFT JOIN search o${index} ON o${index}.entity_id = e.entity_id AND o${index}.key = ?${
      shown ? ` AND ${shown.sql}` : ''
    }`;
    params.push(key, ...(shown?.params ?? []));
  });
  sql += ' WHERE 1 = 1';
  sql = append(sql, params, [
    visibleTo(viewer),
    ...(request.filter === undefined
      ? []
      : [predicateToSql(request.filter, viewer)]),
  ]);
  const orderBy = order.length
    ? ` ORDER BY ${order
        .map(
          (field, index) =>
            `value${index} IS NULL, value${index} ${direction(field.order)}`,
        )
        .join(', ')}, entity_id ASC`
    : ' ORDER BY entity_ref ASC';
  // SQLite needs a LIMIT before OFFSET; -1 means no limit.
  sql += `${orderBy} LIMIT ?`;
  params.push(limit === undefined ? -1 : limit + 1);
  if (offset !== undefined) {
    sql += ' OFFSET ?';
    params.push(offset);
  }
  sql += `) page${orderBy}`;

  const { results } = await db
    .prepare(sql)
    .bind(...params)
    .all<{ final_entity: string }>();
  const hasNextPage = limit !== undefined && results.length > limit;
  const items = results.map(row => row.final_entity);
  return { items: hasNextPage ? items.slice(0, -1) : items, hasNextPage };
}

/** Entities by ref, in request order, `null` where there is no match. */
export async function entitiesByRefs(
  db: D1Database,
  viewer: string,
  entityRefs: string[],
  filter?: unknown,
): Promise<(string | null)[]> {
  if (!entityRefs.length) {
    return [];
  }
  const served = servedTo(viewer);
  const params: unknown[] = [...served.params, JSON.stringify(entityRefs)];
  let sql = `SELECT e.entity_ref AS entity_ref, ${
    served.sql
  } AS final_entity FROM final_entities e WHERE ${inJsonArray('e.entity_ref')}`;
  sql = append(sql, params, [
    visibleTo(viewer),
    ...(filter === undefined ? [] : [predicateToSql(filter, viewer)]),
  ]);
  const { results } = await db
    .prepare(sql)
    .bind(...params)
    .all<{ entity_ref: string; final_entity: string }>();
  const byRef = new Map(results.map(row => [row.entity_ref, row.final_entity]));
  return entityRefs.map(ref => byRef.get(ref) ?? null);
}

/**
 * An entity and every entity it was emitted from, each with its direct
 * parents: `/entities/by-name/.../ancestry`. Returns the response body, or
 * `null` when the root entity does not exist for `viewer`. Ancestors the
 * viewer may not see are left out, as items and as parents.
 */
export async function entityAncestry(
  db: D1Database,
  viewer: string,
  rootRef: string,
): Promise<string | null> {
  const visibleParent = visibleTo(viewer, 'p');
  const visible = visibleTo(viewer);
  const served = servedTo(viewer);
  const { results } = await db
    .prepare(
      `WITH RECURSIVE ancestry (entity_ref) AS (
         SELECT ?
         UNION
         SELECT r.source_entity_ref FROM refresh_state_references r
         JOIN ancestry a ON r.target_entity_ref = a.entity_ref
       )
       SELECT e.entity_ref AS ref, ${served.sql} AS entity, (
         SELECT json_group_array(p.entity_ref) FROM refresh_state_references r
         JOIN final_entities p ON p.entity_ref = r.source_entity_ref
         WHERE r.target_entity_ref = e.entity_ref AND (${visibleParent.sql})
       ) AS parents
       FROM ancestry a JOIN final_entities e ON e.entity_ref = a.entity_ref
       WHERE (${visible.sql})
       ORDER BY e.entity_ref = ? DESC, e.entity_ref`,
    )
    .bind(
      rootRef,
      ...served.params,
      ...visibleParent.params,
      ...visible.params,
      rootRef,
    )
    .all<{ ref: string; entity: string; parents: string }>();
  // The root sorts first. Without it there is nothing to show, whatever
  // else of its ancestry the viewer may see.
  if (results.at(0)?.ref !== rootRef) {
    return null;
  }
  const items = results.map(
    row => `{"entity":${row.entity},"parentEntityRefs":${row.parents}}`,
  );
  return `{"rootEntityRef":${JSON.stringify(rootRef)},"items":[${items.join(
    ',',
  )}]}`;
}

/**
 * The entity by that ref, in lower case, as `viewer` is served it, or
 * `null` when there is none for them.
 */
export async function entityByRef(
  db: D1Database,
  viewer: string,
  ref: string,
): Promise<string | null> {
  const served = servedTo(viewer);
  const visible = visibleTo(viewer);
  return db
    .prepare(
      `SELECT ${served.sql} AS final_entity FROM final_entities e WHERE e.entity_ref = ? AND (${visible.sql})`,
    )
    .bind(...served.params, ref, ...visible.params)
    .first<string>('final_entity');
}

/** The entity, or `null` when there is none by that name for `viewer`. */
export const entityByName = (
  db: D1Database,
  viewer: string,
  kind: string,
  namespace: string,
  name: string,
) => entityByRef(db, viewer, `${kind}:${namespace}/${name}`.toLowerCase());

export type Facets = Record<string, { value: string; count: number }[]>;

/** Value counts per requested facet: `/entity-facets`. */
export async function entityFacets(
  db: D1Database,
  viewer: string,
  facets: string[],
  filter?: unknown,
): Promise<Facets> {
  const keys = facets.map(facet => facet.toLowerCase());
  // The values of a relation are other entities' refs: those of entities
  // the viewer may not see are neither listed nor counted.
  const shown = relationRowsShown(viewer, keys, 's');
  const params: unknown[] = [];
  const sql = `${append(
    'SELECT s.key AS facet, s.original_value AS value, count(*) AS count FROM search s JOIN (SELECT e.entity_id AS entity_id FROM final_entities e WHERE 1 = 1',
    params,
    [
      visibleTo(viewer),
      ...(filter === undefined ? [] : [predicateToSql(filter, viewer)]),
    ],
  )}) f ON f.entity_id = s.entity_id WHERE ${inJsonArray('s.key')}${
    shown ? ` AND ${shown.sql}` : ''
  } AND s.original_value IS NOT NULL GROUP BY s.key, s.original_value ORDER BY s.key, s.original_value`;
  params.push(JSON.stringify(keys), ...(shown?.params ?? []));

  const { results } = await db
    .prepare(sql)
    .bind(...params)
    .all<{ facet: string; value: string; count: number }>();
  return Object.fromEntries(
    facets.map(facet => [
      facet,
      results
        .filter(row => row.facet === facet.toLowerCase())
        .map(row => ({ value: String(row.value), count: Number(row.count) })),
    ]),
  );
}
