import { Hono, type MiddlewareHandler } from 'hono';
import { filedUnder, LEFT_THE_CATALOG, registerAgain } from './accounts';
import { inJsonArray } from './catalog/filter';
import { fileAddress } from './catalog/locations';
import { copySignedInUsers } from './catalog/users';
import {
  authenticationError,
  conflictError,
  inputError,
  notFoundError,
} from './errors';
import { isRecord, rawJson, readJson } from './json';
import {
  appendTaskEvents,
  DRY_RUN_ID,
  readDryRunRequest,
  saveActions,
  saveDryRunResult,
  saveTemplatingExtensions,
  type TaskEvent,
} from './scaffolder';
import type { AppEnv } from './types';

/**
 * What the GitHub Actions pipelines call (`/api/pipeline`). The Backstage
 * backend cannot run on Workers, so the pipelines run the real one and push
 * its results here: the processed catalog, built documentation, the
 * scaffolder's actions, the events of template runs and the results of the
 * template editor's dry runs.
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
// What a dry run wrote comes back as base64, with the log: allow twice the
// size of a request.
const MAX_DRY_RUN_RESULT_BYTES = 10 * 1024 * 1024;
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
  const swap = [
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
  ];
  const results = await c.env.DB.batch<Record<string, number>>([
    ...swap,
    // Counted before the signed-in users are added, so the pipeline can
    // compare the counts with what it sent.
    c.env.DB.prepare(
      'SELECT (SELECT count(*) FROM final_entities) AS entities, (SELECT count(*) FROM search) AS searchRows, (SELECT count(*) FROM search_documents) AS documents, (SELECT count(*) FROM techdocs_sites) AS sites',
    ),
    // The swap removed everyone who signed in. They go back in, except
    // those the new catalog defines itself.
    ...copySignedInUsers(c.env.DB, {
      sql: IS_CURRENT_SYNC,
      params: [syncId],
    }),
    // Files that were unregistered, when the new catalog holds nothing of
    // theirs any more. Until then their rows hide what it does hold.
    c.env.DB.prepare(
      `DELETE FROM locations WHERE ${LEFT_THE_CATALOG} AND ${IS_CURRENT_SYNC}`,
    ).bind(syncId),
    // An owner assigned in the portal belongs to the entity it was given
    // to. When that entity is gone, so is the override: an entity of the
    // same name that comes later, of whatever account, is another one.
    c.env.DB.prepare(
      `DELETE FROM ownership_overrides WHERE entity_ref NOT IN (SELECT entity_ref FROM final_entities) AND ${IS_CURRENT_SYNC}`,
    ).bind(syncId),
    c.env.DB.prepare(
      'DELETE FROM portal_state WHERE key = ? AND value = ?',
    ).bind(SYNC_KEY, syncId),
  ]).catch(rejectedRows);
  const counts = results[swap.length];
  const finished = results[results.length - 1];
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

pipelineRoutes.put('/scaffolder/templating-extensions', async c => {
  const extensions = await readJson(c, MAX_VALUE_BYTES);
  if (!isRecord(extensions)) {
    throw inputError('The templating extensions must be a JSON object');
  }
  await saveTemplatingExtensions(c.env.DB, extensions);
  return c.json({ received: true });
});

// The files to read. One that was unregistered is not read any more.
pipelineRoutes.get('/locations', async c => {
  const { results } = await c.env.DB.prepare(
    'SELECT type, target FROM locations WHERE removed_at IS NULL ORDER BY created_at, target',
  ).all();
  return c.json({ items: results });
});

// What a template run registered. It is filed under the account of whoever
// started the run, as that account stands now; `taskId` is the portal's
// task. A file reported without a task the portal knows is nobody's, and
// shown to no one until a portal administrator registers it again.
pipelineRoutes.post('/locations', async c => {
  const body = await readJson(c, MAX_ROWS_BYTES);
  if (
    !isRecord(body) ||
    body.type !== 'url' ||
    typeof body.target !== 'string' ||
    !URL.canParse(body.target) ||
    new URL(body.target).protocol !== 'https:' ||
    (body.taskId !== undefined && typeof body.taskId !== 'string')
  ) {
    throw inputError(
      'A location needs type "url" and an https target; taskId, when given, is the id of the task that registered it',
    );
  }
  // One spelling for a file on GitHub, so that it is one row.
  const file = fileAddress(body.target);
  const target = file?.target ?? body.target;
  // The rows that are this file already: at either of its addresses, in
  // any letter case (catalog/locations.ts).
  const repository = file
    ? `https://github.com/${file.repository}/`.toLowerCase()
    : target.toLowerCase();
  const { results } = await c.env.DB.prepare(
    'SELECT target, removed_at IS NOT NULL AS removed FROM locations WHERE type = ?1 AND substr(lower(target), 1, length(?2)) = ?2',
  )
    .bind(body.type, repository)
    .all<{ target: string; removed: number }>();
  const rows = results.filter(row =>
    file
      ? fileAddress(row.target)?.key === file.key
      : row.target.toLowerCase() === repository,
  );
  const account = `(SELECT ${filedUnder(
    'lower(t.created_by)',
  )} FROM tasks t WHERE t.id = ?3)`;
  const spellings = JSON.stringify(rows.map(row => row.target));
  if (rows.every(row => row.removed) && rows.length) {
    // Unregistered, and its entities in the catalog until a sync has run
    // without them. For the account that had it, it is registered again,
    // as of now. For any other it stays as it is: registered now, the
    // entities of the account before would be shown to this one.
    await c.env.DB.prepare(
      `UPDATE locations SET ${registerAgain(
        account,
      )} WHERE removed_at IS NOT NULL AND type = ?1 AND target = ?2 AND account = ${account}`,
    )
      .bind(
        body.type,
        rows.find(row => row.target.toLowerCase() === target.toLowerCase())
          ?.target ?? rows[0].target,
        body.taskId ?? null,
      )
      .run();
  } else {
    // A file already registered stays whose it is.
    await c.env.DB.prepare(
      `INSERT INTO locations (type, target, account) SELECT ?1, ?2, ${account} WHERE NOT EXISTS (SELECT 1 FROM locations WHERE type = ?1 AND (lower(target) = lower(?2) OR ${inJsonArray(
        'target',
      )})) ON CONFLICT DO NOTHING`,
    )
      .bind(body.type, target, body.taskId ?? null, spellings)
      .run();
  }
  return c.json({ type: body.type, target });
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

// The task a template run is for: which template, the values of its form,
// and who started it. The workflow is started with the task's id and the
// template's name only, because everyone who can see the pipeline's
// repository can read a run's inputs and its name. Answered only while the
// task waits to be run: a task is run once.
pipelineRoutes.get('/tasks/:taskId', async c => {
  const taskId = c.req.param('taskId');
  const task = await c.env.DB.prepare(
    "SELECT json_object('templateRef', json_extract(spec, '$.templateInfo.entityRef'), 'values', json(coalesce(json_extract(spec, '$.parameters'), '{}')), 'createdBy', created_by) AS task FROM tasks WHERE id = ? AND status = 'open'",
  )
    .bind(taskId)
    .first<string>('task');
  if (!task) {
    throw notFoundError(`No task with id '${taskId}' is waiting to be run`);
  }
  return rawJson(task);
});

function requireDryRunId(id: string): string {
  if (!DRY_RUN_ID.test(id)) {
    throw inputError(`${JSON.stringify(id)} is not a dry run id`);
  }
  return id;
}

// What the template editor asked to be tried out. It can hold the secrets
// of the template form, so it is handed to the pipeline and to nobody else.
pipelineRoutes.get('/dry-runs/:id', async c => {
  const id = requireDryRunId(c.req.param('id'));
  const request = await readDryRunRequest(c.env.TECHDOCS, id);
  if (!request) {
    throw notFoundError(`No dry run with id '${id}' is waiting`);
  }
  return rawJson(request.body);
});

// What the pipeline's scaffolder answered: its HTTP status and JSON body.
// The editor's request, still open, is answered with exactly that.
pipelineRoutes.put('/dry-runs/:id', async c => {
  const id = requireDryRunId(c.req.param('id'));
  const result = await readJson(c, MAX_DRY_RUN_RESULT_BYTES);
  // The scaffolder answers 200 or an error. Anything else has no body to
  // pass on, or is no answer to the editor's request.
  if (
    !isRecord(result) ||
    typeof result.status !== 'number' ||
    !Number.isInteger(result.status) ||
    (result.status !== 200 && (result.status < 400 || result.status > 599)) ||
    !isRecord(result.body)
  ) {
    throw inputError(
      'A dry run result needs a status (200, or an error from 400 to 599) and a body object',
    );
  }
  // Stored as it was sent: Hono keeps the bytes readJson read.
  if (
    !(await saveDryRunResult(c.env.TECHDOCS, id, await c.req.arrayBuffer()))
  ) {
    throw notFoundError(`No dry run with id '${id}' is waiting`);
  }
  return c.json({ received: true });
});

pipelineRoutes.all('*', c => {
  throw notFoundError(
    `${c.req.method} ${c.req.path} is not a pipeline endpoint`,
  );
});
