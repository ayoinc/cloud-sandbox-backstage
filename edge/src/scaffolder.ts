import { Hono, type Context } from 'hono';
import { streamSSE } from 'hono/streaming';
import { sourceLocation, type Entity } from './catalog/entity';
import { inJsonArray } from './catalog/filter';
import { entityByName } from './catalog/queries';
import { inputError, notFoundError } from './errors';
import { isRecord, rawJson, readJson } from './json';
import type { AppEnv } from './types';

/**
 * The Backstage scaffolder API (`/api/scaffolder`) for a deployment that
 * cannot run template steps itself. Creating a task stores it and starts a
 * GitHub Actions workflow in the portal repository. The workflow runs the
 * template with the real Backstage scaffolder and reports its events to
 * `/api/pipeline`; the task pages read them here.
 *
 * A user reads only the tasks they created: a task holds the values typed
 * into the template form.
 */
export const scaffolderRoutes = new Hono<AppEnv>();

const ACTIONS_KEY = 'scaffolder-actions';
const WORKFLOW_FILE = 'portal-scaffold.yml';
const MAX_TASK_BYTES = 256 * 1024;

// D1 allows 50 queries per request on the Workers free plan. One long poll
// and one event stream each stay under that, then end so the client asks
// again from the last event it saw.
const POLL_INTERVAL_MS = 2000;
const LONG_POLL_MS = 25_000;
const MAX_STREAM_POLLS = 40;

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
  db: D1Database,
  { kind, namespace, name }: EntityName,
): Promise<TemplateEntity> {
  if (kind.toLowerCase() !== 'template') {
    throw inputError("Invalid kind, only 'Template' kind is supported");
  }
  const entity = await entityByName(db, kind, namespace, name);
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

/** Replaces the actions list with the one a real scaffolder backend reports. */
export const saveActions = (db: D1Database, actions: unknown[]) =>
  db
    .prepare(
      'INSERT INTO portal_state (key, value) VALUES (?, ?) ON CONFLICT (key) DO UPDATE SET value = excluded.value',
    )
    .bind(ACTIONS_KEY, JSON.stringify(actions))
    .run();

scaffolderRoutes.get('/v2/actions', async c => {
  const actions = await c.env.DB.prepare(
    'SELECT value FROM portal_state WHERE key = ?',
  )
    .bind(ACTIONS_KEY)
    .first<string>('value');
  return rawJson(actions ?? '[]');
});

scaffolderRoutes.get(
  '/v2/templates/:namespace/:kind/:name/parameter-schema',
  async c => {
    const { metadata, spec } = await findTemplate(c.env.DB, c.req.param());
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

/** Starts the pipeline run for a task. Returns the reason if it did not start. */
async function dispatchWorkflow(
  env: Env,
  inputs: Record<string, string>,
): Promise<string | undefined> {
  try {
    const response = await fetch(
      `https://api.github.com/repos/${env.PORTAL_REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches`,
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
    } when asked to run ${WORKFLOW_FILE} in ${env.PORTAL_REPO} on ${
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
  const template = await findTemplate(c.env.DB, ref);
  const templateRef = `${ref.kind}:${ref.namespace}/${ref.name}`.toLowerCase();
  const createdBy = c.get('user').userEntityRef;
  const userEntity = await c.env.DB.prepare(
    'SELECT final_entity FROM final_entities WHERE entity_ref = ?',
  )
    .bind(createdBy.toLowerCase())
    .first<string>('final_entity');

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

  // Form secrets are deliberately not passed on: workflow inputs are
  // readable by everyone who can see the workflow run.
  const failure =
    problem ??
    (await dispatchWorkflow(c.env, {
      task_id: taskId,
      template_ref: templateRef,
      values: JSON.stringify(body.values),
      created_by: createdBy,
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
  let events = await listEvents(c.env.DB, taskId, after);
  while (!events.length && Date.now() < deadline) {
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
  return streamSSE(c, async stream => {
    for (let poll = 0; poll < MAX_STREAM_POLLS && !stream.aborted; poll++) {
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
