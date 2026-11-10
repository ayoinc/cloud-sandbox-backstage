import { inJsonArray, predicateToSql, type SqlFragment } from './filter';

/**
 * Catalog read queries against D1. Ports of `DefaultEntitiesCatalog` in
 * `@backstage/plugin-catalog-backend`, kept to the same SQL shape so results
 * and paging match the Backstage backend.
 *
 * Entities are returned as the stored JSON text and are never parsed here.
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

/** Filter, POST query and full-text conditions for an entity aliased `e`. */
function conditions(
  cursor: QueryCursor,
  sortKey: string | undefined,
  sortRowInScope: boolean,
): SqlFragment[] {
  const result: SqlFragment[] = [];
  if (cursor.filter !== undefined) {
    result.push(predicateToSql(cursor.filter));
  }
  if (cursor.query !== undefined) {
    result.push(predicateToSql(cursor.query));
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
      result.push({
        sql: `e.entity_id IN (SELECT s.entity_id FROM search s WHERE ${inJsonArray(
          's.key',
        )} AND instr(s.value, ?) > 0)`,
        params: [JSON.stringify(fields), term],
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
  request: QueryEntitiesRequest,
): Promise<QueryEntitiesResult> {
  const { cursor } = request;
  const limit = request.limit ?? DEFAULT_QUERY_LIMIT;
  const sortField = cursor.orderFields.at(0);
  const sortKey = sortField?.field.toLowerCase();
  const backwards = cursor.isPrevious;
  const descending = sortField?.order === 'desc';

  const params: unknown[] = [];
  let sql = sortKey
    ? 'WITH filtered AS (SELECT e.entity_id AS entity_id, e.final_entity AS final_entity, o.value AS value FROM search o JOIN final_entities e ON e.entity_id = o.entity_id WHERE o.key = ? AND o.value IS NOT NULL'
    : 'WITH filtered AS (SELECT e.entity_id AS entity_id, e.final_entity AS final_entity FROM final_entities e WHERE 1 = 1';
  if (sortKey) {
    params.push(sortKey);
  }
  sql = append(sql, params, conditions(cursor, sortKey, Boolean(sortKey)));
  sql += ') SELECT * FROM filtered';

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
  sql += ` ORDER BY ${
    sortKey ? `value ${order}, ` : ''
  }entity_id ${order} LIMIT ?`;
  params.push(backwards ? limit : limit + 1);
  if (request.isInitial && request.offset !== undefined) {
    sql += ' OFFSET ?';
    params.push(request.offset);
  }

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
      countSql +=
        ' AND EXISTS (SELECT 1 FROM search o WHERE o.entity_id = e.entity_id AND o.key = ? AND o.value IS NOT NULL)';
      countParams.push(sortKey);
    }
    countSql = append(
      countSql,
      countParams,
      conditions(cursor, sortKey, false),
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
  request: ListEntitiesRequest,
): Promise<{ items: string[]; hasNextPage: boolean }> {
  const { order, limit, offset } = request;
  const params: unknown[] = [];
  let sql = 'SELECT e.final_entity AS final_entity FROM final_entities e';
  order.forEach(({ field }, index) => {
    sql += ` LEFT JOIN search o${index} ON o${index}.entity_id = e.entity_id AND o${index}.key = ?`;
    params.push(field.toLowerCase());
  });
  sql += ' WHERE 1 = 1';
  if (request.filter !== undefined) {
    sql = append(sql, params, [predicateToSql(request.filter)]);
  }
  sql += order.length
    ? ` ORDER BY ${order
        .map(
          (field, index) =>
            `o${index}.value IS NULL, o${index}.value ${direction(
              field.order,
            )}`,
        )
        .join(', ')}, e.entity_id ASC`
    : ' ORDER BY e.entity_ref ASC';
  // SQLite needs a LIMIT before OFFSET; -1 means no limit.
  sql += ' LIMIT ?';
  params.push(limit === undefined ? -1 : limit + 1);
  if (offset !== undefined) {
    sql += ' OFFSET ?';
    params.push(offset);
  }

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
  entityRefs: string[],
  filter?: unknown,
): Promise<(string | null)[]> {
  if (!entityRefs.length) {
    return [];
  }
  const params: unknown[] = [JSON.stringify(entityRefs)];
  let sql = `SELECT e.entity_ref AS entity_ref, e.final_entity AS final_entity FROM final_entities e WHERE ${inJsonArray(
    'e.entity_ref',
  )}`;
  if (filter !== undefined) {
    sql = append(sql, params, [predicateToSql(filter)]);
  }
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
 * `null` when the root entity does not exist.
 */
export async function entityAncestry(
  db: D1Database,
  rootRef: string,
): Promise<string | null> {
  const { results } = await db
    .prepare(
      `WITH RECURSIVE ancestry (entity_ref) AS (
         SELECT ?1
         UNION
         SELECT r.source_entity_ref FROM refresh_state_references r
         JOIN ancestry a ON r.target_entity_ref = a.entity_ref
       )
       SELECT e.final_entity AS entity, (
         SELECT json_group_array(p.entity_ref) FROM refresh_state_references r
         JOIN final_entities p ON p.entity_ref = r.source_entity_ref
         WHERE r.target_entity_ref = e.entity_ref
       ) AS parents
       FROM ancestry a JOIN final_entities e ON e.entity_ref = a.entity_ref
       ORDER BY e.entity_ref = ?1 DESC, e.entity_ref`,
    )
    .bind(rootRef)
    .all<{ entity: string; parents: string }>();
  if (!results.length) {
    return null;
  }
  const items = results.map(
    row => `{"entity":${row.entity},"parentEntityRefs":${row.parents}}`,
  );
  return `{"rootEntityRef":${JSON.stringify(rootRef)},"items":[${items.join(
    ',',
  )}]}`;
}

export async function entityByName(
  db: D1Database,
  kind: string,
  namespace: string,
  name: string,
): Promise<string | null> {
  const ref = `${kind}:${namespace}/${name}`.toLowerCase();
  return db
    .prepare('SELECT final_entity FROM final_entities WHERE entity_ref = ?')
    .bind(ref)
    .first<string>('final_entity');
}

export type Facets = Record<string, { value: string; count: number }[]>;

/** Value counts per requested facet: `/entity-facets`. */
export async function entityFacets(
  db: D1Database,
  facets: string[],
  filter?: unknown,
): Promise<Facets> {
  const params: unknown[] = [];
  let sql =
    'SELECT s.key AS facet, s.original_value AS value, count(*) AS count FROM search s';
  if (filter !== undefined) {
    const predicate = predicateToSql(filter);
    sql += ` JOIN (SELECT e.entity_id AS entity_id FROM final_entities e WHERE ${predicate.sql}) f ON f.entity_id = s.entity_id`;
    params.push(...predicate.params);
  }
  sql += ` WHERE ${inJsonArray(
    's.key',
  )} AND s.original_value IS NOT NULL GROUP BY s.key, s.original_value ORDER BY s.key, s.original_value`;
  params.push(JSON.stringify(facets.map(facet => facet.toLowerCase())));

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
