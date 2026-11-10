import { Hono, type MiddlewareHandler } from 'hono';
import {
  authenticationError,
  conflictError,
  inputError,
  notFoundError,
} from './errors';
import { isRecord, readJson } from './json';
import { appendTaskEvents, saveActions, type TaskEvent } from './scaffolder';
import type { AppEnv } from './types';

/**
 * What the GitHub Actions pipelines call (`/api/pipeline`). The Backstage
 * backend cannot run on Workers, so the pipelines run the real one and push
 * its results here: the processed catalog, built documentation, the
 * scaffolder's actions and the events of template runs.
 *
 * Callers present the PIPELINE_TOKEN secret, never a user token.
 */
export const pipelineRoutes = new Hono<AppEnv>();

const MAX_ROWS = 500;
const MAX_ROWS_BYTES = 400 * 1024;
// D1 stores at most 2 MB in one value. The margin leaves room for the
// difference between a request body and what is stored from it.
const MAX_VALUE_BYTES = 1_900_000;
const MAX_EVENTS = 1000;
const MAX_KEYS_BYTES = 1024 * 1024;
// R2 deletes at most 1000 objects in one call and lists as many per page.
const R2_PAGE_SIZE = 1000;

const SYNC_KEY = 'catalog-sync';
const EVENT_TYPES = ['log', 'completion', 'cancelled', 'recovered'];

const encoder = new TextEncoder();

const requirePipelineToken: MiddlewareHandler<AppEnv> = async (c, next) => {
  const [scheme, token] = (c.req.header('authorization') ?? '').split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) {
    throw authenticationError('Missing pipeline token');
  }
  // Both sides are hashed so the comparison takes the same time whatever
  // the length or content of the token that was sent.
  const [given, expected] = await Promise.all(
    [token, c.env.PIPELINE_TOKEN ?? ''].map(value =>
      crypto.subtle.digest('SHA-256', encoder.encode(value)),
    ),
  );
  if (
    !c.env.PIPELINE_TOKEN ||
    !crypto.subtle.timingSafeEqual(given, expected)
  ) {
    throw authenticationError('Invalid pipeline token');
  }
  await next();
};

pipelineRoutes.use('*', requirePipelineToken);

/**
 * The tables a catalog sync replaces, with their columns in the order rows
 * arrive. Rows are staged in `staging_<table>` first. Search rows refer to
 * entities, so the order here is the order they can be inserted in.
 */
const STAGED: Record<string, { columns: string[]; nullable?: string[] }> = {
  final_entities: { columns: ['entity_id', 'entity_ref', 'final_entity'] },
  search: {
    columns: ['entity_id', 'key', 'value', 'original_value'],
    nullable: ['value', 'original_value'],
  },
  refresh_state_references: {
    columns: ['source_entity_ref', 'target_entity_ref'],
  },
  search_documents: { columns: ['title', 'text', 'type', 'document'] },
  techdocs_sites: { columns: ['entity_ref', 'site_id'] },
};

// Every statement of a sync carries this condition, so a sync that was
// replaced by a newer one, or already committed, changes nothing.
const IS_CURRENT_SYNC = `EXISTS (SELECT 1 FROM portal_state WHERE key = '${SYNC_KEY}' AND value = ?)`;

/** Turns D1's rejection of a row into a 400 that names the broken rule. */
function rejectedRows(error: unknown): never {
  if (error instanceof Error && /constraint/i.test(error.message)) {
    throw inputError(`Rows were rejected: ${error.message}`);
  }
  throw error;
}

/** The body of a request that belongs to one catalog sync. */
function syncRequest(
  body: unknown,
): Record<string, unknown> & { syncId: string } {
  if (!isRecord(body) || typeof body.syncId !== 'string') {
    throw inputError('syncId is required');
  }
  return { ...body, syncId: body.syncId };
}

pipelineRoutes.post('/catalog/begin', async c => {
  const syncId = crypto.randomUUID();
  await c.env.DB.batch([
    ...Object.keys(STAGED).map(table =>
      c.env.DB.prepare(`DELETE FROM staging_${table}`),
    ),
    c.env.DB.prepare(
      'INSERT INTO portal_state (key, value) VALUES (?, ?) ON CONFLICT (key) DO UPDATE SET value = excluded.value',
    ).bind(SYNC_KEY, syncId),
  ]);
  return c.json({ syncId });
});

pipelineRoutes.post('/catalog/rows', async c => {
  const { syncId, table, rows } = syncRequest(
    await readJson(c, MAX_ROWS_BYTES),
  );
  if (typeof table !== 'string' || !Object.hasOwn(STAGED, table)) {
    throw inputError(`table must be one of ${Object.keys(STAGED).join(', ')}`);
  }
  if (!Array.isArray(rows) || rows.length > MAX_ROWS) {
    throw inputError(`rows must be an array of at most ${MAX_ROWS} rows`);
  }
  const { columns, nullable = [] } = STAGED[table];
  rows.forEach((row: unknown, index) => {
    const valid =
      Array.isArray(row) &&
      row.length === columns.length &&
      row.every(
        (value, column) =>
          typeof value === 'string' ||
          (value === null && nullable.includes(columns[column])),
      );
    if (!valid) {
      throw inputError(
        `Row ${index} must be [${columns.join(', ')}] as strings`,
      );
    }
  });
  // The rows travel as one JSON parameter: D1 allows 100 parameters a
  // statement, which 500 rows would exceed many times over.
  const [, current] = await c.env.DB.batch([
    c.env.DB.prepare(
      `INSERT INTO staging_${table} (${columns.join(', ')}) SELECT ${columns
        .map((_, column) => `json_extract(value, '$[${column}]')`)
        .join(', ')} FROM json_each(?) WHERE ${IS_CURRENT_SYNC}`,
    ).bind(JSON.stringify(rows), syncId),
    c.env.DB.prepare(`SELECT 1 WHERE ${IS_CURRENT_SYNC}`).bind(syncId),
  ]).catch(rejectedRows);
  if (!current.results.length) {
    throw conflictError(`${syncId} is not the catalog sync in progress`);
  }
  return c.json({ received: rows.length });
});

pipelineRoutes.post('/catalog/commit', async c => {
  const { syncId } = syncRequest(await readJson(c, MAX_ROWS_BYTES));
  const tables = Object.entries(STAGED);
  const whenCurrent = (sql: string) =>
    c.env.DB.prepare(`${sql} WHERE ${IS_CURRENT_SYNC}`).bind(syncId);
  // One batch is one transaction: readers see the old catalog or the new
  // one, and a rejected row leaves the old one in place.
  const results = await c.env.DB.batch<Record<string, number>>([
    ...[...tables]
      .reverse()
      .map(([table]) => whenCurrent(`DELETE FROM ${table}`)),
    ...tables.map(([table, { columns }]) =>
      whenCurrent(
        `INSERT INTO ${table} (${columns.join(', ')}) SELECT ${columns.join(
          ', ',
        )} FROM staging_${table}`,
      ),
    ),
    ...tables.map(([table]) => whenCurrent(`DELETE FROM staging_${table}`)),
    c.env.DB.prepare(
      'SELECT (SELECT count(*) FROM final_entities) AS entities, (SELECT count(*) FROM search) AS searchRows, (SELECT count(*) FROM search_documents) AS documents, (SELECT count(*) FROM techdocs_sites) AS sites',
    ),
    c.env.DB.prepare(
      'DELETE FROM portal_state WHERE key = ? AND value = ?',
    ).bind(SYNC_KEY, syncId),
  ]).catch(rejectedRows);
  const [counts, finished] = results.slice(-2);
  if (finished.meta.changes !== 1) {
    throw conflictError(`${syncId} is not the catalog sync in progress`);
  }
  return c.json(counts.results[0]);
});

pipelineRoutes.put('/scaffolder/actions', async c => {
  const actions = await readJson(c, MAX_VALUE_BYTES);
  if (!Array.isArray(actions)) {
    throw inputError('The actions list must be a JSON array');
  }
  await saveActions(c.env.DB, actions);
  return c.json({ received: actions.length });
});

pipelineRoutes.get('/locations', async c => {
  const { results } = await c.env.DB.prepare(
    'SELECT type, target FROM locations ORDER BY created_at, target',
  ).all();
  return c.json({ items: results });
});

pipelineRoutes.post('/locations', async c => {
  const body = await readJson(c, MAX_ROWS_BYTES);
  if (
    !isRecord(body) ||
    body.type !== 'url' ||
    typeof body.target !== 'string' ||
    !URL.canParse(body.target) ||
    new URL(body.target).protocol !== 'https:'
  ) {
    throw inputError('A location needs type "url" and an https target');
  }
  await c.env.DB.prepare(
    'INSERT INTO locations (type, target) VALUES (?, ?) ON CONFLICT DO NOTHING',
  )
    .bind(body.type, body.target)
    .run();
  return c.json({ type: body.type, target: body.target });
});

/** Documentation lives under `sites/<siteId>/`; nothing else is writable. */
function requireSiteKey(key: unknown): string {
  if (
    typeof key !== 'string' ||
    !/^sites\/[a-z0-9-]+\/./.test(key) ||
    key.split('/').some(part => part === '' || part === '.' || part === '..')
  ) {
    throw inputError(
      `Invalid object key ${JSON.stringify(
        key,
      )}, expected sites/<siteId>/<path>`,
    );
  }
  return key;
}

pipelineRoutes.get('/techdocs/manifest', async c => {
  const objects: { key: string; etag: string }[] = [];
  let cursor: string | undefined;
  do {
    const page = await c.env.TECHDOCS.list({
      prefix: 'sites/',
      limit: R2_PAGE_SIZE,
      cursor,
    });
    objects.push(...page.objects.map(({ key, etag }) => ({ key, etag })));
    cursor = page.truncated ? page.cursor : undefined;
  } while (cursor);
  return c.json({ objects });
});

pipelineRoutes.put('/techdocs/object/:key{.+}', async c => {
  const key = requireSiteKey(c.req.param('key'));
  // R2 takes a stream only when its length is known. A body sent without a
  // length is read into memory first.
  await c.env.TECHDOCS.put(
    key,
    c.req.header('content-length') ? c.req.raw.body : await c.req.arrayBuffer(),
    { httpMetadata: { contentType: c.req.header('content-type') } },
  );
  return c.json({ key });
});

pipelineRoutes.post('/techdocs/delete', async c => {
  const body = await readJson(c, MAX_KEYS_BYTES);
  if (!isRecord(body) || !Array.isArray(body.keys)) {
    throw inputError('keys must be an array');
  }
  const keys = body.keys.map(requireSiteKey);
  for (let start = 0; start < keys.length; start += R2_PAGE_SIZE) {
    await c.env.TECHDOCS.delete(keys.slice(start, start + R2_PAGE_SIZE));
  }
  return c.json({ deleted: keys.length });
});

function requireEvent(event: unknown, index: number): TaskEvent {
  if (
    !isRecord(event) ||
    typeof event.type !== 'string' ||
    !EVENT_TYPES.includes(event.type) ||
    !isRecord(event.body) ||
    typeof event.createdAt !== 'string' ||
    Number.isNaN(Date.parse(event.createdAt))
  ) {
    throw inputError(
      `Event ${index} needs a type (${EVENT_TYPES.join(
        ', ',
      )}), a body object and an ISO 8601 createdAt`,
    );
  }
  return {
    type: event.type,
    body: event.body,
    createdAt: new Date(event.createdAt).toISOString(),
  };
}

pipelineRoutes.post('/tasks/:taskId/events', async c => {
  const body = await readJson(c, MAX_VALUE_BYTES);
  if (
    !isRecord(body) ||
    !Array.isArray(body.events) ||
    body.events.length > MAX_EVENTS ||
    (body.spec !== undefined && !isRecord(body.spec))
  ) {
    throw inputError(
      `events must be an array of at most ${MAX_EVENTS} events, and spec an object`,
    );
  }
  const events = body.events.map(requireEvent);
  await appendTaskEvents(c.env.DB, c.req.param('taskId'), events, body.spec);
  return c.json({ received: events.length });
});

pipelineRoutes.all('*', c => {
  throw notFoundError(
    `${c.req.method} ${c.req.path} is not a pipeline endpoint`,
  );
});
