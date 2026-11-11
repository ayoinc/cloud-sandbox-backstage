/**
 * Shows a task what its GitHub Actions run is doing before the template
 * starts.
 *
 * A template runs in a workflow that first has to get a runner, check out
 * the repository and install its dependencies; only then does the pipeline
 * script start reporting. Until it does, the task would sit on "Queued".
 * While a task is still `open`, the event endpoints call `check()` between
 * their polls: it reads the run's steps from GitHub and adds one log line
 * per step that started or ended. Lines are keyed, so several viewers and
 * reconnecting streams add each line once.
 */

const WORKFLOW_FILE = 'portal-scaffold.yml';
const CHECK_EVERY_MS = 6000;
// Runner housekeeping, of no interest to the person waiting.
const QUIET_STEP = /^(Set up job|Complete job|Post )/;

interface WorkflowRun {
  id: number;
  name?: string;
  display_title?: string;
  status: string;
  html_url: string;
}

interface WorkflowStep {
  name: string;
  status: string;
  conclusion: string | null;
  number: number;
  started_at?: string | null;
  completed_at?: string | null;
}

interface Line {
  key: string;
  message: string;
  status?: 'failed';
}

async function github<T>(env: Env, path: string): Promise<T | undefined> {
  const response = await fetch(
    `https://api.github.com/repos/${env.PORTAL_REPO}${path}`,
    {
      headers: {
        accept: 'application/vnd.github+json',
        authorization: `Bearer ${env.PORTAL_GITHUB_TOKEN}`,
        'user-agent': 'cloud-sandbox-portal',
        'x-github-api-version': '2022-11-28',
      },
    },
  ).catch(() => undefined);
  return response?.ok ? response.json<T>() : undefined;
}

const seconds = (from?: string | null, to?: string | null) =>
  from && to
    ? `, ${Math.max(
        1,
        Math.round((Date.parse(to) - Date.parse(from)) / 1000),
      )} s`
    : '';

function stepLines(steps: WorkflowStep[]): Line[] {
  const lines: Line[] = [];
  for (const step of steps) {
    if (QUIET_STEP.test(step.name) || step.status === 'queued') {
      continue;
    }
    lines.push({
      key: `step-${step.number}-start`,
      message: `GitHub Actions: ${step.name}…`,
    });
    if (step.status === 'completed' && step.conclusion !== 'skipped') {
      const failed = step.conclusion === 'failure';
      lines.push({
        key: `step-${step.number}-end`,
        message: `GitHub Actions: ${step.name} ${
          failed ? 'failed' : 'done'
        }${seconds(step.started_at, step.completed_at)}`,
        ...(failed && { status: 'failed' as const }),
      });
    }
  }
  return lines;
}

/**
 * A reporter for one request. `check()` is cheap to call on every poll: it
 * does nothing until `CHECK_EVERY_MS` has passed, and nothing at all once
 * the task has left `open`. Each check costs at most two GitHub requests
 * (one once the run is known) and one database batch.
 */
export function runProgress(env: Env, taskId: string) {
  let nextCheck = 0;
  let run: WorkflowRun | undefined;
  let finished = !env.PORTAL_GITHUB_TOKEN;
  const sent = new Set<string>();

  return {
    async check(): Promise<void> {
      if (finished || Date.now() < nextCheck) {
        return;
      }
      nextCheck = Date.now() + CHECK_EVERY_MS;

      const lines: Line[] = [];
      if (!run) {
        // The workflow puts the task id in the name of its run.
        const list = await github<{ workflow_runs: WorkflowRun[] }>(
          env,
          `/actions/workflows/${WORKFLOW_FILE}/runs?event=workflow_dispatch&per_page=20`,
        );
        run = list?.workflow_runs.find(candidate =>
          `${candidate.display_title} ${candidate.name}`.includes(taskId),
        );
      }
      if (run) {
        lines.push({
          key: 'run',
          message: `GitHub Actions run started: ${run.html_url}`,
        });
        const jobs = await github<{
          jobs: { status: string; steps?: WorkflowStep[] }[];
        }>(env, `/actions/runs/${run.id}/jobs?per_page=5`);
        const job = jobs?.jobs.at(0);
        if (job?.status === 'queued') {
          lines.push({
            key: 'runner',
            message: 'GitHub Actions: waiting for a runner…',
          });
        }
        lines.push(...stepLines(job?.steps ?? []));
      }

      const fresh = lines.filter(line => !sent.has(line.key));
      const createdAt = new Date().toISOString();
      // Each line is added only while the task is still open and only if no
      // request has added it yet. They sit under the first step, where the
      // task page shows log lines.
      const results = await env.DB.batch<{ status: string }>([
        ...fresh.map(line =>
          env.DB.prepare(
            `INSERT INTO task_events (task_id, event_type, body, created_at)
             SELECT id, 'log', json_patch(json_object(
               'message', ?2, 'source', 'github-actions', 'key', ?3,
               'stepId', json_extract(spec, '$.steps[0].id')), ?4), ?5
             FROM tasks
             WHERE id = ?1 AND status = 'open' AND NOT EXISTS (
               SELECT 1 FROM task_events
               WHERE task_id = ?1 AND json_extract(body, '$.key') = ?3)`,
          ).bind(
            taskId,
            line.message,
            line.key,
            JSON.stringify(line.status ? { status: line.status } : {}),
            createdAt,
          ),
        ),
        env.DB.prepare('SELECT status FROM tasks WHERE id = ?').bind(taskId),
      ]);
      fresh.forEach(line => sent.add(line.key));
      // Once the pipeline script reports, the task is its own to describe.
      finished = results.at(-1)?.results.at(0)?.status !== 'open';
    },
  };
}
