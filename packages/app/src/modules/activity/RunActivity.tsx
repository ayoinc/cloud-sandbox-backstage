import { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { useApi } from '@backstage/core-plugin-api';
import { scaffolderApiRef } from '@backstage/plugin-scaffolder-react';
import { RunActivityCard } from '@internal/brand';
import type { RunActivityLine } from '@internal/brand';

interface Activity {
  state: 'running' | 'done' | 'failed';
  phase: string;
  startedAt: number;
  endedAt?: number;
  lines: RunActivityLine[];
  runUrl?: string;
}

interface TaskEvent {
  id: number;
  type: string;
  createdAt: string;
  body: {
    message?: string;
    status?: string;
    source?: string;
    error?: { message?: string };
  };
}

// Colour codes the scaffolder's logger writes into its messages.
// eslint-disable-next-line no-control-regex
const ANSI = /\u001b\[[0-9;]*m/g;
const RUN_URL = /https:\/\/github\.com\/\S+\/actions\/runs\/\d+/;

/**
 * The part of an event a person waiting for the run wants to see, or
 * nothing: the steps of the GitHub Actions run, each template step starting
 * and ending, warnings, errors and what was registered. The full log stays
 * on the task page.
 */
function importantLine(event: TaskEvent): RunActivityLine | undefined {
  const message = (event.body.message ?? '').replace(ANSI, '').trim();
  const line = (text: string, tone?: RunActivityLine['tone']) => ({
    id: event.id,
    text,
    tone,
  });
  if (
    event.body.status === 'failed' ||
    /^(error|ResponseError|Error)\b/i.test(message)
  ) {
    return line(message.split('\n')[0].replace(/^error:\s*/i, ''), 'error');
  }
  if (event.body.source === 'github-actions') {
    return RUN_URL.test(message)
      ? line('GitHub Actions run started')
      : line(message.replace(/^GitHub Actions:\s*/, ''));
  }
  const step = /^(Beginning|Finished|Skipping) step (.+)$/.exec(message);
  if (step) {
    if (step[1] === 'Beginning') return line(`${step[2]}…`);
    if (step[1] === 'Finished') return line(`${step[2]} done`, 'success');
    return line(`${step[2]} skipped`);
  }
  if (/^warn(ing)?:/i.test(message)) {
    return line(message.replace(/^warn(ing)?:\s*/i, ''), 'warning');
  }
  if (
    /^(Queued\.|Preparing to run|The template run has started|Registered )/.test(
      message,
    )
  ) {
    return line(message.split(/, follow it at| in GitHub Actions:/)[0]);
  }
  return undefined;
}

function phaseOf(event: TaskEvent, current: string): string {
  const message = event.body.message ?? '';
  if (event.body.source === 'github-actions') return 'Preparing the runner';
  if (/^Queued\./.test(message)) return 'Queued in GitHub Actions';
  if (/^Preparing to run/.test(message)) return 'Starting the template';
  const step = /^Beginning step (.+)$/.exec(message.replace(ANSI, ''));
  if (step) return step[1];
  return current;
}

const initial = (): Activity => ({
  state: 'running',
  phase: 'Starting',
  startedAt: Date.now(),
  lines: [],
});

/**
 * Follows the task on the page, if the page is a template run
 * (`/create/tasks/<id>`), and shows its progress in the corner.
 */
export function RunActivity() {
  const { pathname } = useLocation();
  const scaffolderApi = useApi(scaffolderApiRef);
  const taskId = /\/create\/tasks\/([0-9a-f-]{36})$/.exec(pathname)?.[1];
  const [activity, setActivity] = useState<Activity>(initial);

  useEffect(() => {
    if (!taskId) {
      return undefined;
    }
    setActivity(initial());
    const seen = new Set<number>();
    const subscription = scaffolderApi.streamLogs({ taskId }).subscribe({
      next: raw => {
        const event = raw as unknown as TaskEvent;
        if (seen.has(event.id)) {
          return;
        }
        seen.add(event.id);
        const at = Date.parse(event.createdAt);
        setActivity(current => {
          const startedAt = Math.min(
            current.startedAt,
            at || current.startedAt,
          );
          if (event.type === 'completion') {
            const failed = Boolean(event.body.error);
            return {
              ...current,
              startedAt,
              endedAt: at || Date.now(),
              state: failed ? 'failed' : 'done',
              phase: failed ? 'The run failed' : 'Finished',
            };
          }
          const line = importantLine(event);
          return {
            ...current,
            startedAt,
            phase: phaseOf(event, current.phase),
            runUrl:
              RUN_URL.exec(event.body.message ?? '')?.[0] ?? current.runUrl,
            lines: line ? [...current.lines, line] : current.lines,
          };
        });
      },
      error: () => {
        // The task page reports a broken stream itself.
      },
    });
    return () => subscription.unsubscribe();
  }, [taskId, scaffolderApi]);

  return taskId ? <RunActivityCard {...activity} /> : null;
}
