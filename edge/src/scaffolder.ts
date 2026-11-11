import { Hono, type Context } from 'hono';
import { streamSSE } from 'hono/streaming';
import type { ContentfulStatusCode } from 'hono/utils/http-status';
import { ADMIN_ONLY_ACTIONS } from '../../packages/backend/src/pipeline/adminActions';
import { callerRef } from './accounts';
import { isPortalAdmin, requirePortalAdmin } from './admin';
import { sourceLocation, type Entity } from './catalog/entity';
import { inJsonArray } from './catalog/filter';
import { entityByName, entityByRef } from './catalog/queries';
import {
  HttpError,
  inputError,
  notAllowedError,
  notFoundError,
} from './errors';
import { isRecord, rawJson, readJson } from './json';
import { runProgress } from './runProgress';
import type { AppEnv } from './types';

/**
 * The Backstage scaffolder API (`/api/scaffolder`) for a deployment that
 * cannot run template steps itself. Creating a task stores it and starts a
 * GitHub Actions workflow in the portal repository. The workflow runs the
 * template with the real Backstage scaffolder and reports its events to
 * `/api/pipeline`; the task pages read them here. The template editor's dry
 * run goes the same way, through a workflow of its own.
 *
 * A user reads only the tasks they created: a task holds the values typed
 * into the template form. A template is run by those who may see it; to
 * everyone else there is no such template. One whose steps change the
 * operator's GitHub organisation is run by portal administrators only.
 */
export const scaffolderRoutes = new Hono<AppEnv>();

const ACTIONS_KEY = 'scaffolder-actions';
const EXTENSIONS_KEY = 'scaffolder-templating-extensions';
const WORKFLOW_FILE = 'portal-scaffold.yml';
const DRY_RUN_WORKFLOW_FILE = 'portal-dry-run.yml';
const MAX_TASK_BYTES = 256 * 1024;
// A dry run carries the template's files. The Backstage backend takes 10 MB;
// here the body is parsed within a Worker's memory and processor time.
const MAX_DRY_RUN_BYTES = 5 * 1024 * 1024;

// The Workers free plan allows 50 subrequests per request, database queries
// and calls to GitHub together. One long poll and one event stream each stay
// under that, counting what runProgress adds (two per six seconds), then end
// so the client asks again from the last event it saw.
const POLL_INTERVAL_MS = 2000;
const LONG_POLL_MS = 25_000;
const MAX_STREAM_POLLS = 25;

// A dry run answers after about a minute and a half, most of it the runner
// installing dependencies. Looking for the result is a subrequest too: the
// first look comes when one could be there, and all of them together (33
// in five minutes) leave room for the rest of the request.
const DRY_RUN_FIRST_CHECK_MS = 40_000;
const DRY_RUN_CHECK_EVERY_MS = 8000;
const DRY_RUN_WAIT_MS = 5 * 60_000;
// The workflow gives up after 15 minutes: nothing older is still in use.
const DRY_RUN_STALE_MS = 20 * 60_000;
const DRY_RUN_PREFIX = 'dry-runs/';
// Who calls a Worker running under `wrangler dev` on this machine. The
// request URL cannot tell that Worker from the deployed one, since wrangler
// gives it the deployed host. On the deployed Worker Cloudflare sets this
// header itself, and never to a loopback address.
const LOCAL_CALLERS = ['127.0.0.1', '::1'];

interface TemplateStep {
  id?: string;
  name?: string;
  action: string;
  [key: string]: unknown;
}

interface ParameterSchema {
  title?: string;
  description?: string;
  [key: string]: unknown;
}

interface TemplateEntity extends Entity {
  spec: {
    parameters?: ParameterSchema | ParameterSchema[];
    presentation?: unknown;
    steps: TemplateStep[];
    output?: unknown;
    formDecorators?: unknown;
    EXPERIMENTAL_formDecorators?: unknown;
    EXPERIMENTAL_recovery?: unknown;
  };
}

interface EntityName {
  kind: string;
  namespace: string;
  name: string;
}

async function findTemplate(
  c: Context<AppEnv>,
  { kind, namespace, name }: EntityName,
): Promise<TemplateEntity> {
  if (kind.toLowerCase() !== 'template') {
    throw inputError("Invalid kind, only 'Template' kind is supported");
  }
  const entity = await entityByName(
    c.env.DB,
    callerRef(c),
    kind,
    namespace,
    name,
  );
  if (entity === null) {
    throw notFoundError(
      `Template ${`${kind}:${namespace}/${name}`.toLowerCase()} not found`,
    );
  }
  const template = JSON.parse(entity) as TemplateEntity;
  if (template.apiVersion !== 'scaffolder.backstage.io/v1beta3') {
    throw inputError(
      `Unsupported apiVersion field in schema entity, ${template.apiVersion}`,
    );
  }
  return template;
}

const saveState = (db: D1Database, key: string, value: unknown) =>
  db
    .prepare(
      'INSERT INTO portal_state (key, value) VALUES (?, ?) ON CONFLICT (key) DO UPDATE SET value = excluded.value',
    )
    .bind(key, JSON.stringify(value))
    .run();

const readState = (db: D1Database, key: string) =>
  db
    .prepare('SELECT value FROM portal_state WHERE key = ?')
    .bind(key)
    .first<string>('value');

/** Replaces the actions list with the one a real scaffolder backend reports. */
export const saveActions = (db: D1Database, actions: unknown[]) =>
  saveState(db, ACTIONS_KEY, actions);

/** Replaces the template filters and globals a real scaffolder backend reports. */
export const saveTemplatingExtensions = (
  db: D1Database,
  extensions: Record<string, unknown>,
) => saveState(db, EXTENSIONS_KEY, extensions);

scaffolderRoutes.get('/v2/actions', async c =>
  rawJson((await readState(c.env.DB, ACTIONS_KEY)) ?? '[]'),
);

// Before the first sync there is nothing to list, which the page shows as
// "no templating extensions".
scaffolderRoutes.get('/v2/templating-extensions', async c =>
  rawJson(
    (await readState(c.env.DB, EXTENSIONS_KEY)) ??
      '{"filters":{},"globals":{"functions":{},"values":{}}}',
  ),
);

scaffolderRoutes.get(
  '/v2/templates/:namespace/:kind/:name/parameter-schema',
  async c => {
    const { metadata, spec } = await findTemplate(c, c.req.param());
    return c.json({
      title: metadata.title ?? metadata.name,
      ...(spec.presentation ? { presentation: spec.presentation } : {}),
      description: metadata.description,
      'ui:options': metadata['ui:options'],
      steps: [spec.parameters ?? []].flat().map(schema => ({
        title: schema.title ?? 'Please enter the following information',
        description: schema.description,
        schema,
      })),
      formDecorators: spec.formDecorators ?? spec.EXPERIMENTAL_formDecorators,
    });
  },
);

/** One scaffolder event: a `log`, `completion`, `cancelled` or `recovered`. */
export interface TaskEvent {
  type: string;
  body: Record<string, unknown>;
  createdAt: string;
}

/**
 * Appends events to a task in order and moves its status along: the first
 * event starts it, a completion ends it as failed if it carries an error,
 * as cancelled if the run was cancelled, and as completed otherwise. `spec`,
 * when given, replaces the stored task spec, except for the user who
 * created the task.
 */
export async function appendTaskEvents(
  db: D1Database,
  taskId: string,
  events: TaskEvent[],
  spec?: Record<string, unknown>,
): Promise<void> {
  const task = await db
    .prepare(
      "SELECT status, json_extract(spec, '$.user') AS user, EXISTS (SELECT 1 FROM task_events WHERE task_id = ?1 AND event_type = 'cancelled' AND id > coalesce((SELECT max(id) FROM task_events WHERE task_id = ?1 AND event_type = 'recovered'), 0)) AS cancelled FROM tasks WHERE id = ?1",
    )
    .bind(taskId)
    .first<{ status: string; user: string | null; cancelled: number }>();
  if (!task) {
    throw notFoundError(`No task with id '${taskId}' found`);
  }
  let { status } = task;
  let cancelled = task.cancelled === 1;
  for (const { type, body } of events) {
    if (type === 'completion') {
      if (cancelled) {
        status = 'cancelled';
      } else {
        status = body.error ? 'failed' : 'completed';
      }
      continue;
    }
    if (type === 'cancelled') {
      cancelled = true;
    }
    if (type === 'recovered') {
      cancelled = false;
    }
    if (status === 'open' || type === 'recovered') {
      status = 'processing';
    }
  }
  // The pipeline's scaffolder runs the template without a user, so the spec
  // it reports has none. The task list shows the owner from the spec.
  const storedSpec = spec && {
    ...spec,
    ...(task.user && { user: JSON.parse(task.user) as unknown }),
  };
  // The rows travel as one JSON parameter: D1 allows 100 parameters a
  // statement, which a batch of events would exceed.
  await db.batch([
    db
      .prepare(
        "INSERT INTO task_events (task_id, event_type, body, created_at) SELECT ?1, json_extract(value, '$[0]'), json_extract(value, '$[1]'), json_extract(value, '$[2]') FROM json_each(?2) ORDER BY key",
      )
      .bind(
        taskId,
        JSON.stringify(
          events.map(({ type, body, createdAt }) => [
            type,
            JSON.stringify(body),
            createdAt,
          ]),
        ),
      ),
    db
      .prepare(
        'UPDATE tasks SET status = ?, last_heartbeat_at = ?, spec = coalesce(?, spec) WHERE id = ?',
      )
      .bind(
        status,
        new Date().toISOString(),
        storedSpec ? JSON.stringify(storedSpec) : null,
        taskId,
      ),
  ]);
}

/** Why the pipeline cannot be started with this configuration, if it cannot. */
function dispatchProblem(env: Env): string | undefined {
  if (!/^[\w.-]+\/[\w.-]+$/.test(env.PORTAL_REPO)) {
    return 'the PORTAL_REPO variable is not set to the portal repository (owner/repo)';
  }
  if (!env.PORTAL_GITHUB_TOKEN) {
    return 'the PORTAL_GITHUB_TOKEN secret is not set';
  }
  return undefined;
}

/**
 * Starts a workflow of the portal repository on PORTAL_REF. Returns the
 * reason if it did not start.
 */
export async function dispatchWorkflow(
  env: Env,
  workflowFile: string,
  inputs?: Record<string, string>,
): Promise<string | undefined> {
  const problem = dispatchProblem(env);
  if (problem) {
    return problem;
  }
  try {
    const response = await fetch(
      `https://api.github.com/repos/${env.PORTAL_REPO}/actions/workflows/${workflowFile}/dispatches`,
      {
        method: 'POST',
        headers: {
          accept: 'application/vnd.github+json',
          authorization: `Bearer ${env.PORTAL_GITHUB_TOKEN}`,
          'content-type': 'application/json',
          'user-agent': 'cloud-sandbox-portal',
          'x-github-api-version': '2022-11-28',
        },
        body: JSON.stringify({ ref: env.PORTAL_REF, inputs }),
      },
    );
    if (response.ok) {
      return undefined;
    }
    const detail = await response
      .json<{ message?: string }>()
      .catch(() => undefined);
    return `GitHub answered ${response.status}${
      detail?.message ? ` (${detail.message})` : ''
    } when asked to run ${workflowFile} in ${env.PORTAL_REPO} on ${
      env.PORTAL_REF
    }`;
  } catch (error) {
    return `GitHub could not be reached (${
      error instanceof Error ? error.message : String(error)
    })`;
  }
}

function parseTemplateRef(ref: string): EntityName {
  const match = /^(?:([^:/]+):)?(?:([^:/]+)\/)?([^:/]+)$/.exec(ref);
  if (!match) {
    throw inputError(
      `Entity reference "${ref}" was not on the form [<kind>:][<namespace>/]<name>`,
    );
  }
  return {
    kind: match[1] ?? 'template',
    namespace: match[2] ?? 'default',
    name: match[3],
  };
}

/** The address the template's own files are fetched relative to. */
function templateBaseUrl(template: TemplateEntity): string | undefined {
  const location = sourceLocation(template);
  if (location?.type === 'url') {
    return location.target;
  }
  return location?.type === 'file' ? `file://${location.target}` : undefined;
}

scaffolderRoutes.post('/v2/tasks', async c => {
  const body = await readJson(c, MAX_TASK_BYTES);
  if (
    !isRecord(body) ||
    typeof body.templateRef !== 'string' ||
    !isRecord(body.values)
  ) {
    throw inputError('templateRef and values are required');
  }
  const ref = parseTemplateRef(body.templateRef);
  const template = await findTemplate(c, ref);
  const templateRef = `${ref.kind}:${ref.namespace}/${ref.name}`.toLowerCase();
  // Such steps act with the portal's own token: inviting people to the
  // organisation, making teams and putting people in them.
  if (
    template.spec.steps.some(step =>
      ADMIN_ONLY_ACTIONS.includes(step.action),
    ) &&
    !(await isPortalAdmin(c))
  ) {
    throw notAllowedError('Only a portal administrator can run this template');
  }
  const createdBy = c.get('user').userEntityRef;
  // As the user is served it: they are in the catalog only for those who
  // may see them, and the task keeps what is read here.
  const userEntity = await entityByRef(c.env.DB, callerRef(c), callerRef(c));

  // Built the way the scaffolder backend builds it, so the task page shows
  // the steps at once. The pipeline replaces it with the spec of the run.
  const steps = template.spec.steps.map((step, index) => ({
    ...step,
    id: step.id ?? `step-${index + 1}`,
    name: step.name ?? step.action,
  }));
  const spec = {
    apiVersion: template.apiVersion,
    steps,
    EXPERIMENTAL_recovery: template.spec.EXPERIMENTAL_recovery,
    output: template.spec.output ?? {},
    parameters: body.values,
    user: {
      entity: userEntity ? (JSON.parse(userEntity) as Entity) : undefined,
      ref: createdBy,
    },
    templateInfo: {
      entityRef: templateRef,
      baseUrl: templateBaseUrl(template),
      entity: { metadata: template.metadata },
    },
  };

  const taskId = crypto.randomUUID();
  const createdAt = new Date().toISOString();
  // The task page shows a log line only under a step, so these go to the first.
  const stepId = steps.at(0)?.id;
  const insertEvent = c.env.DB.prepare(
    "INSERT INTO task_events (task_id, event_type, body, created_at) VALUES (?, 'log', ?, ?)",
  );
  const problem = dispatchProblem(c.env);
  await c.env.DB.batch([
    c.env.DB.prepare(
      "INSERT INTO tasks (id, spec, status, created_by, created_at) VALUES (?, ?, 'open', ?, ?)",
    ).bind(taskId, JSON.stringify(spec), createdBy, createdAt),
    ...(problem
      ? []
      : [
          insertEvent.bind(
            taskId,
            JSON.stringify({
              message: `Queued. The template runs in GitHub Actions, follow it at https://github.com/${c.env.PORTAL_REPO}/actions/workflows/${WORKFLOW_FILE}`,
              stepId,
            }),
            createdAt,
          ),
        ]),
  ]);

  // The workflow is given the task's id and the template's name, and asks
  // for the rest with the pipeline's token (GET /api/pipeline/tasks/<id>):
  // the inputs and the name of a run are readable by everyone who can see
  // the portal's repository, which the form values and who filled them in
  // are not for. Form secrets are not passed on at all.
  const failure =
    problem ??
    (await dispatchWorkflow(c.env, WORKFLOW_FILE, {
      task_id: taskId,
      template_ref: templateRef,
    }));
  if (failure) {
    const message = `Could not start the pipeline: ${failure}`;
    const failedAt = new Date().toISOString();
    await appendTaskEvents(c.env.DB, taskId, [
      {
        type: 'log',
        body: { message, stepId, status: 'failed' },
        createdAt: failedAt,
      },
      {
        type: 'completion',
        body: {
          message: 'Run completed with status: failed',
          error: { name: 'Error', message },
        },
        createdAt: failedAt,
      },
    ]);
  }
  return c.json({ id: taskId }, 201);
});

/** The ids dry runs are given here. They become part of object keys. */
export const DRY_RUN_ID = /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/;

// A dry run is two objects in the bucket, next to the documentation sites.
// Nothing serves them: documentation routes read `sites/` only, so the
// request reaches the pipeline alone and the result only the admin who waits.
const dryRunKey = (id: string, part: 'request' | 'result') =>
  `${DRY_RUN_PREFIX}${id}/${part}.json`;

/** The request of a dry run that is still waited for, or `null`. */
export const readDryRunRequest = (bucket: R2Bucket, id: string) =>
  bucket.get(dryRunKey(id, 'request'));

/**
 * Stores what the pipeline's scaffolder answered, as JSON text of
 * `{ status, body }`. Returns false when nobody waits for it any more.
 */
export async function saveDryRunResult(
  bucket: R2Bucket,
  id: string,
  result: ArrayBuffer,
): Promise<boolean> {
  if (!(await bucket.head(dryRunKey(id, 'request')))) {
    return false;
  }
  await bucket.put(dryRunKey(id, 'result'), result, {
    httpMetadata: { contentType: 'application/json' },
  });
  return true;
}

/**
 * Removes what earlier dry runs left behind. The route below deletes its
 * own two objects, but not when the browser went away while it waited, or
 * when the workflow wrote that it could not start after the route gave up.
 */
async function removeStaleDryRuns(bucket: R2Bucket): Promise<void> {
  const { objects } = await bucket.list({ prefix: DRY_RUN_PREFIX });
  const before = Date.now() - DRY_RUN_STALE_MS;
  const stale = objects
    .filter(object => object.uploaded.getTime() < before)
    .map(object => object.key);
  if (stale.length) {
    await bucket.delete(stale);
  }
}

// The template editor trying a template out. The request is handed to the
// portal-dry-run workflow through the bucket, because it is too large and
// too private for workflow inputs, which everyone who can see the run can
// read. The editor's request stays open until the workflow has put the
// result there, and gets it with the status the real scaffolder answered:
// 200 with what the steps wrote, or 400 with what is wrong with the values.
scaffolderRoutes.post('/v2/dry-run', async c => {
  await requirePortalAdmin(c);
  const body = await readJson(c, MAX_DRY_RUN_BYTES);
  if (
    !isRecord(body) ||
    !isRecord(body.values) ||
    (body.secrets !== undefined &&
      (!isRecord(body.secrets) ||
        Object.values(body.secrets).some(
          secret => typeof secret !== 'string',
        ))) ||
    !Array.isArray(body.directoryContents) ||
    body.directoryContents.some(
      file =>
        !isRecord(file) ||
        typeof file.path !== 'string' ||
        typeof file.base64Content !== 'string',
    )
  ) {
    throw inputError(
      'Malformed request: values must be an object, secrets an object of strings and directoryContents a list of { path, base64Content }',
    );
  }
  if (!isRecord(body.template)) {
    throw inputError('Input template is not a template');
  }

  const bucket = c.env.TECHDOCS;
  const id = crypto.randomUUID();
  const requestKey = dryRunKey(id, 'request');
  const resultKey = dryRunKey(id, 'result');
  await removeStaleDryRuns(bucket);
  // Stored as it was sent: Hono keeps the bytes readJson read.
  await bucket.put(requestKey, await c.req.arrayBuffer(), {
    httpMetadata: { contentType: 'application/json' },
  });
  try {
    if (
      c.env.LOCAL_DRY_RUN_WITHOUT_GITHUB === 'true' &&
      LOCAL_CALLERS.includes(c.req.header('cf-connecting-ip') ?? '')
    ) {
      // Local development without GitHub: the developer is the pipeline.
      console.log(
        `Dry run ${id} is waiting. Answer it from another terminal: PORTAL_URL=http://localhost:8787 PORTAL_DRY_RUN_ID=${id} yarn workspace @internal/edge template:dry-run (PORTAL_URL is where this Worker listens)`,
      );
    } else {
      const failure = await dispatchWorkflow(c.env, DRY_RUN_WORKFLOW_FILE, {
        dry_run_id: id,
      });
      if (failure) {
        throw new HttpError(
          503,
          'ServiceUnavailableError',
          `Could not start the dry run: ${failure}`,
        );
      }
    }

    const deadline = Date.now() + DRY_RUN_WAIT_MS;
    for (
      let wait = DRY_RUN_FIRST_CHECK_MS;
      Date.now() + wait <= deadline;
      wait = DRY_RUN_CHECK_EVERY_MS
    ) {
      await scheduler.wait(wait);
      const stored = await bucket.get(resultKey);
      if (stored) {
        const result = await stored.json<{ status: number; body: unknown }>();
        return c.json(result.body, result.status as ContentfulStatusCode);
      }
    }
    throw new HttpError(
      504,
      'GatewayTimeoutError',
      `The dry run did not report back within ${
        DRY_RUN_WAIT_MS / 60_000
      } minutes. It runs in GitHub Actions, see https://github.com/${
        c.env.PORTAL_REPO
      }/actions/workflows/${DRY_RUN_WORKFLOW_FILE}`,
    );
  } finally {
    await bucket.delete([requestKey, resultKey]);
  }
});

interface TaskRow {
  id: string;
  spec: string;
  status: string;
  created_by: string;
  created_at: string;
  last_heartbeat_at: string | null;
}

const TASK_COLUMNS =
  'id, spec, status, created_by, created_at, last_heartbeat_at';
const TASK_ORDER_FIELDS = ['created_at', 'status', 'created_by'];

/** A task as the scaffolder API returns it. The stored spec is sent as it is. */
function serialiseTask(row: TaskRow): string {
  const rest = JSON.stringify({
    status: row.status,
    createdAt: row.created_at,
    lastHeartbeatAt: row.last_heartbeat_at ?? undefined,
    createdBy: row.created_by,
  });
  return `{"id":${JSON.stringify(row.id)},"spec":${row.spec},${rest.slice(1)}`;
}

function parseCount(value: string | undefined, name: string): number {
  // SQLite reads a negative LIMIT as no limit.
  const count = value === undefined ? -1 : Number(value);
  if (!Number.isInteger(count) || (value !== undefined && count < 0)) {
    throw inputError(`Invalid ${name}, expected a non-negative integer`);
  }
  return count;
}

scaffolderRoutes.get('/v2/tasks', async c => {
  const where = ['created_by = ?'];
  const params: unknown[] = [c.get('user').userEntityRef];
  for (const [column, values] of [
    ['created_by', c.req.queries('createdBy')],
    ['status', c.req.queries('status')],
  ] as const) {
    if (values) {
      where.push(inJsonArray(column));
      params.push(JSON.stringify(values));
    }
  }
  const order = (c.req.queries('order') ?? []).map(item => {
    const [, direction, field] = /^(asc|desc):(.+)$/.exec(item) ?? [];
    if (!direction) {
      throw inputError(
        `Invalid order parameter "${item}", expected "<asc or desc>:<field name>"`,
      );
    }
    if (!TASK_ORDER_FIELDS.includes(field)) {
      throw inputError(`Invalid order field "${field}"`);
    }
    return `${field} ${direction}`;
  });
  const condition = where.join(' AND ');
  const [tasks, total] = await c.env.DB.batch<TaskRow & { count: number }>([
    c.env.DB.prepare(
      `SELECT ${TASK_COLUMNS} FROM tasks WHERE ${condition} ORDER BY ${
        order.length ? order.join(', ') : 'created_at desc'
      } LIMIT ? OFFSET ?`,
    ).bind(
      ...params,
      parseCount(c.req.query('limit'), 'limit'),
      Math.max(parseCount(c.req.query('offset'), 'offset'), 0),
    ),
    c.env.DB.prepare(
      `SELECT count(*) AS count FROM tasks WHERE ${condition}`,
    ).bind(...params),
  ]);
  return rawJson(
    `{"tasks":[${tasks.results.map(serialiseTask).join(',')}],"totalTasks":${
      total.results[0].count
    }}`,
  );
});

/** The task, if the signed-in user created it. Other users' tasks do not exist. */
async function ownTask(c: Context<AppEnv>, taskId: string): Promise<TaskRow> {
  const task = await c.env.DB.prepare(
    `SELECT ${TASK_COLUMNS} FROM tasks WHERE id = ? AND created_by = ?`,
  )
    .bind(taskId, c.get('user').userEntityRef)
    .first<TaskRow>();
  if (!task) {
    throw notFoundError(`No task with id '${taskId}' found`);
  }
  return task;
}

scaffolderRoutes.get('/v2/tasks/:taskId', async c =>
  rawJson(serialiseTask(await ownTask(c, c.req.param('taskId')))),
);

interface EventRow {
  id: number;
  event_type: string;
  body: string;
  created_at: string;
}

/**
 * A task's events after event `after`, oldest first, each with its JSON as
 * the scaffolder API sends it (the stored body goes out as it is). As in
 * the Backstage task store, the completion event is always included, so a
 * client that reconnects late still learns the task has ended, and a task
 * that started over replays only what happened since.
 */
async function listEvents(
  db: D1Database,
  taskId: string,
  after: number | undefined,
): Promise<{ id: number; type: string; json: string }[]> {
  const { results } = await db
    .prepare(
      "SELECT id, event_type, body, created_at FROM task_events WHERE task_id = ?1 AND (?2 IS NULL OR id > ?2 OR event_type = 'completion') ORDER BY id",
    )
    .bind(taskId, after ?? null)
    .all<EventRow>();
  const recovered = results.map(row => row.event_type).lastIndexOf('recovered');
  const recovery: unknown =
    recovered < 0 ? undefined : JSON.parse(results[recovered].body);
  let replayed = results;
  if (isRecord(recovery) && recovery.recoverStrategy === 'startOver') {
    replayed = recovered === results.length - 1 ? [] : results.slice(recovered);
  }
  return replayed.map(row => ({
    id: row.id,
    type: row.event_type,
    json: `{"id":${row.id},"taskId":${JSON.stringify(taskId)},"body":${
      row.body
    },"type":${JSON.stringify(row.event_type)},"createdAt":${JSON.stringify(
      row.created_at,
    )}}`,
  }));
}

function parseAfter(value: string | undefined): number | undefined {
  const after = Number(value);
  return value !== undefined && Number.isFinite(after) ? after : undefined;
}

// Long polling: answers as soon as there are events. The client asks again
// straight away, so an empty answer is held back until the wait runs out.
scaffolderRoutes.get('/v2/tasks/:taskId/events', async c => {
  const taskId = c.req.param('taskId');
  await ownTask(c, taskId);
  const after = parseAfter(c.req.query('after'));
  const deadline = Date.now() + LONG_POLL_MS;
  const progress = runProgress(c.env, taskId);
  let events = await listEvents(c.env.DB, taskId, after);
  while (!events.length && Date.now() < deadline) {
    await progress.check();
    await scheduler.wait(POLL_INTERVAL_MS);
    events = await listEvents(c.env.DB, taskId, after);
  }
  return rawJson(`[${events.map(event => event.json).join(',')}]`);
});

// Server-sent events. A Worker has nothing that pushes new events to it, so
// the stream reads D1 on an interval. It ends after the completion event, or
// when its share of D1 queries is used up: the client then reconnects with
// `after` set to the last event it received.
scaffolderRoutes.get('/v2/tasks/:taskId/eventstream', async c => {
  const taskId = c.req.param('taskId');
  await ownTask(c, taskId);
  let after = parseAfter(c.req.query('after'));
  const progress = runProgress(c.env, taskId);
  return streamSSE(c, async stream => {
    for (let poll = 0; poll < MAX_STREAM_POLLS && !stream.aborted; poll++) {
      await progress.check();
      for (const event of await listEvents(c.env.DB, taskId, after)) {
        await stream.writeSSE({ event: event.type, data: event.json });
        if (event.type === 'completion') {
          return;
        }
        after = event.id;
      }
      await stream.sleep(POLL_INTERVAL_MS);
    }
  });
});
