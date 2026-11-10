// Runs one software template for the portal.
//
// The portal stores the task a user created and starts the portal-scaffold
// workflow, which runs this script. It starts the pipeline backend, creates
// the same task in its real Backstage scaffolder, and passes every event the
// scaffolder emits on to the portal as it happens, so the user watches the
// run live. Whatever goes wrong, the portal's task is brought to an end.
//
//   PORTAL_TASK_ID       id of the portal's task
//   PORTAL_TEMPLATE_REF  the template, e.g. template:default/nodejs-service
//   PORTAL_TASK_VALUES   the form values, as JSON
//   PORTAL_CREATED_BY    entity ref of the user who started it
//
// The other settings are described in settings.mjs.
import { setTimeout as sleep } from 'node:timers/promises';
import {
  backendRequest,
  prepareDataDir,
  startBackend,
  writeRunConfig,
} from './backend.mjs';
import { readProcessingErrors, waitForCatalog } from './catalog.mjs';
import { portalRequest } from './portal.mjs';
import { dataDirFor, readSettings } from './settings.mjs';

// Within the limits of POST /api/pipeline/tasks/<id>/events
const MAX_EVENTS_PER_REQUEST = 500;
const MAX_EVENT_BYTES_PER_REQUEST = 1_000_000;

const { portal, github, githubToken, runUrl } = readSettings();
const dataDir = dataDirFor('pipeline-scaffold');
const taskId = process.env.PORTAL_TASK_ID;
const templateRef = process.env.PORTAL_TEMPLATE_REF;
const createdBy = process.env.PORTAL_CREATED_BY;

// Values that must never leave this machine, even if a template step or an
// error message happens to contain one.
const secrets = [portal.token, githubToken].filter(Boolean);
const redact = text =>
  secrets.reduce((result, secret) => result.replaceAll(secret, '***'), text);

let completionSent = false;

/**
 * Appends events (and optionally the task spec) to the portal's task, in as
 * many requests as their number and size need.
 */
async function report(events, spec) {
  const batches = [[]];
  let bytes = 0;
  for (const event of events) {
    const size = Buffer.byteLength(JSON.stringify(event));
    if (
      batches.at(-1).length === MAX_EVENTS_PER_REQUEST ||
      (bytes > 0 && bytes + size > MAX_EVENT_BYTES_PER_REQUEST)
    ) {
      batches.push([]);
      bytes = 0;
    }
    batches.at(-1).push(event);
    bytes += size;
  }
  for (const [index, batch] of batches.entries()) {
    await portalRequest(
      portal,
      'POST',
      `/api/pipeline/tasks/${encodeURIComponent(taskId)}/events`,
      {
        body: redact(
          JSON.stringify({
            events: batch,
            ...(index === 0 && spec && { spec }),
          }),
        ),
        contentType: 'application/json',
        retry: true,
      },
    );
    for (const { type, body } of batch) {
      console.log(
        redact(
          `[${type}]${body.stepId ? ` ${body.stepId}:` : ''} ${
            body.message ?? JSON.stringify(body)
          }`,
        ),
      );
    }
    completionSent ||= batch.some(event => event.type === 'completion');
  }
}

const logEvent = message => ({
  type: 'log',
  body: { message },
  createdAt: new Date().toISOString(),
});

/** Ends the portal's task as failed, unless it has already ended. */
async function reportFailure(message) {
  if (completionSent) {
    return;
  }
  await report([
    logEvent(message),
    {
      type: 'completion',
      body: {
        message: 'Run completed with status: failed',
        error: { name: 'Error', message },
      },
      createdAt: new Date().toISOString(),
    },
  ]);
}

/**
 * Waits until the catalog can hand out the template. The run starts as soon
 * as it can; once the catalog has processed everything it was given, a
 * template that is still missing is not going to come.
 */
async function waitForTemplate(backend, locations) {
  const match = /^(?:([^:/]+):)?(?:([^/]+)\/)?([^:/]+)$/.exec(templateRef);
  if (!match) {
    throw new Error(`"${templateRef}" is not a template reference.`);
  }
  const [, kind = 'template', namespace = 'default', name] = match;
  const path = `/api/catalog/entities/by-name/${[kind, namespace, name]
    .map(encodeURIComponent)
    .join('/')}`;

  let catalogEnded;
  waitForCatalog(dataDir, locations).then(
    () => {
      catalogEnded = 'The catalog has processed every location.';
    },
    error => {
      catalogEnded = error.message;
    },
  );
  for (;;) {
    const ended = catalogEnded;
    try {
      await backendRequest(backend, path);
      return;
    } catch (error) {
      if (error.status !== 404) {
        throw error;
      }
    }
    if (ended) {
      const failures = readProcessingErrors(dataDir, [])
        .configured.slice(0, 5)
        .map(({ entityRef, messages }) => `${entityRef}: ${messages[0]}`);
      throw new Error(
        [
          `Template ${templateRef} is not in the catalog.`,
          ended,
          ...failures,
        ].join('\n'),
      );
    }
    await sleep(1000);
  }
}

const locationTargets = async backend =>
  (await backendRequest(backend, '/api/catalog/locations'))
    .map(({ data }) => data)
    .filter(location => location.type === 'url')
    .map(location => location.target);

/** The form values the user filled in. */
function taskValues() {
  try {
    const values = JSON.parse(process.env.PORTAL_TASK_VALUES || '{}');
    if (values && typeof values === 'object' && !Array.isArray(values)) {
      return values;
    }
  } catch {
    // Reported below, without echoing what was sent.
  }
  throw new Error('PORTAL_TASK_VALUES is not a JSON object.');
}

/** Runs the template and returns the status the scaffolder ended with. */
async function run() {
  if (!taskId || !templateRef) {
    throw new Error('PORTAL_TASK_ID and PORTAL_TEMPLATE_REF must be set.');
  }
  const values = taskValues();

  console.log(
    `Running ${templateRef} for ${
      createdBy || 'an unknown user'
    } (portal task ${taskId})`,
  );
  await report([
    logEvent(
      `Preparing to run ${templateRef}${
        runUrl ? ` in GitHub Actions: ${runUrl}` : ''
      }`,
    ),
  ]);

  const { items: registered } = await portalRequest(
    portal,
    'GET',
    '/api/pipeline/locations',
    { retry: true },
  );
  await prepareDataDir(dataDir);
  const locations = await writeRunConfig(dataDir, { github, registered });
  const backend = await startBackend({ dataDir, githubToken });
  secrets.push(backend.token);
  try {
    await waitForTemplate(backend, locations);
    const knownTargets = new Set(await locationTargets(backend));

    let created;
    try {
      created = await backendRequest(backend, '/api/scaffolder/v2/tasks', {
        method: 'POST',
        json: { templateRef, values },
      });
    } catch (error) {
      // The scaffolder answers 400 with the schema errors of the form values.
      const invalid = error.body?.errors?.map(e => e.stack ?? e.message);
      throw invalid
        ? new Error(`The form values were rejected: ${invalid.join('; ')}`)
        : error;
    }
    const taskPath = `/api/scaffolder/v2/tasks/${created.id}`;
    const { spec } = await backendRequest(backend, taskPath);
    await report([logEvent('The template run has started')], spec);

    let after;
    for (;;) {
      // Answers as soon as there are new events, or empty after 30 seconds.
      const events = await backendRequest(
        backend,
        `${taskPath}/events${after === undefined ? '' : `?after=${after}`}`,
      );
      if (events.length === 0) {
        continue;
      }
      after = events.at(-1).id;
      const forwarded = events.map(({ type, body, createdAt }) => ({
        type,
        body,
        createdAt: new Date(createdAt).toISOString(),
      }));
      const completion = forwarded.find(event => event.type === 'completion');
      if (!completion) {
        await report(forwarded);
        continue;
      }

      // The run is over. Before the portal is told, hand it the catalog
      // files the run registered: the pipeline backend forgets them when it
      // stops, and the portal gives them to every later sync.
      const earlier = forwarded.filter(event => event !== completion);
      if (earlier.length > 0) {
        await report(earlier);
      }
      const { status } = await backendRequest(backend, taskPath);
      for (const target of await locationTargets(backend)) {
        if (!knownTargets.has(target)) {
          await portalRequest(portal, 'POST', '/api/pipeline/locations', {
            json: { type: 'url', target },
            retry: true,
          });
          await report([
            logEvent(
              `Registered ${target} with the portal. It appears in the catalog after the next sync.`,
            ),
          ]);
        }
      }
      if (status === 'failed' && !completion.body.error) {
        // Some failures end with a message only. The portal tells a failed
        // run from a finished one by the error.
        completion.body.error = {
          name: 'Error',
          message: completion.body.message,
        };
      }
      await report([completion]);
      return status;
    }
  } finally {
    await backend.stop();
  }
}

async function fail(message, detail) {
  console.error(redact(`\nTemplate run failed: ${detail ?? message}`));
  try {
    await reportFailure(redact(message));
  } catch (error) {
    console.error(`The failure could not be reported: ${error.message}`);
  }
  process.exit(1);
}

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.once(signal, () =>
    fail(
      'The GitHub Actions run was cancelled or timed out before the template finished.',
    ),
  );
}

try {
  const status = await run();
  console.log(`\nTemplate run ended with status: ${status}`);
  process.exit(status === 'completed' ? 0 : 1);
} catch (error) {
  // The first line is for the user; the rest (backend output) stays here.
  await fail(
    `The template could not be run: ${error.message.split('\n')[0]}`,
    error.message,
  );
}
