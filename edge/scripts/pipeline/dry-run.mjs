// Tries a template out for the portal's template editor.
//
// The editor sends the template, its files and the form values to the portal,
// which stores them and starts the portal-dry-run workflow, which runs this
// script. It fetches that request, hands it to the dry run of a real
// Backstage scaffolder, and gives the portal the answer, whatever it is: what
// the steps wrote, or what is wrong with the values. The editor's request is
// still open and is answered with it. Whatever goes wrong here, the editor
// is told so too.
//
// The request holds a template that is nobody else's business, and can hold
// secrets from its form: nothing of it or of the answer is printed.
//
//   PORTAL_DRY_RUN_ID  id of the dry run, from the portal
//
// The other settings are described in settings.mjs.
import {
  backendRequest,
  prepareDataDir,
  startBackend,
  writeRunConfig,
} from './backend.mjs';
import { connectPortal } from './bridge.mjs';
import { portalRequest } from './portal.mjs';
import { dataDirFor, readSettings } from './settings.mjs';

const DRY_RUN_PATH = '/api/scaffolder/v2/dry-run';

const settings = readSettings();
const { githubToken, runUrl } = settings;
const dataDir = dataDirFor('pipeline-dry-run');
// Set once the portal can be called: see connectPortal.
let portal;
const dryRunId = process.env.PORTAL_DRY_RUN_ID ?? '';
const resultPath = `/api/pipeline/dry-runs/${dryRunId}`;

// Values that must never leave this machine, even if a template step or an
// error message happens to contain one.
const secrets = [
  settings.portal?.token,
  settings.cloudflare?.apiToken,
  githubToken,
].filter(Boolean);
const redact = text =>
  secrets.reduce((result, secret) => result.replaceAll(secret, '***'), text);

let resultSent = false;

/** Gives the portal the answer the editor is waiting for. */
async function report(status, body) {
  await portalRequest(portal, 'PUT', resultPath, {
    body: redact(JSON.stringify({ status, body })),
    contentType: 'application/json',
    retry: true,
  });
  resultSent = true;
}

/** Tries the template out and returns the status the scaffolder answered. */
async function run() {
  // The id is put into a URL. The portal makes it with crypto.randomUUID.
  if (!/^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/.test(dryRunId)) {
    throw new Error('PORTAL_DRY_RUN_ID is not a dry run id.');
  }
  // Before anything that can fail: only then can the editor be told why.
  portal = await connectPortal(settings, dataDir);
  secrets.push(portal.token);
  console.log(`Trying out a template (portal dry run ${dryRunId})`);

  const request = await portalRequest(portal, 'GET', resultPath, {
    retry: true,
  });
  await prepareDataDir(dataDir);
  // The dry run uses no catalog entity; the backend reads the catalog anyway.
  await writeRunConfig(dataDir, { github: undefined, registered: [] });
  const backend = await startBackend({ dataDir, githubToken });
  secrets.push(backend.token);
  let status = 200;
  let body;
  try {
    body = await backendRequest(backend, DRY_RUN_PATH, {
      method: 'POST',
      json: request,
    });
  } catch (error) {
    // An answer that is not 200 is as much a result as one that is: 400
    // lists what is wrong with the form values, and an error from a step is
    // what the template's author needs to read.
    if (!error.status) {
      throw new Error('The scaffolder did not answer the dry run.');
    }
    if (!error.body) {
      // What it sent instead may quote the template.
      throw new Error(
        `The scaffolder answered the dry run with ${error.status} and no JSON.`,
      );
    }
    ({ status, body } = error);
  } finally {
    await backend.stop();
  }
  await report(status, body);
  return status;
}

/** Stops the portal Worker, if this script started one, and ends. */
async function leave(code) {
  await portal?.stop();
  process.exit(code);
}

async function fail(message, detail) {
  console.error(redact(`\nDry run failed: ${detail ?? message}`));
  if (!portal) {
    console.error(
      'The portal was never reached, so the editor was not told about the failure.',
    );
    process.exit(1);
  }
  if (!resultSent) {
    const text = redact(`${message}${runUrl ? ` See ${runUrl}` : ''}`);
    try {
      // The Backstage error format, which the editor shows the message of.
      await report(500, {
        error: { name: 'Error', message: text },
        request: { method: 'POST', url: '/v2/dry-run' },
        response: { statusCode: 500 },
      });
    } catch (error) {
      console.error(`The failure could not be reported: ${error.message}`);
    }
  }
  await leave(1);
}

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.once(signal, () =>
    fail(
      'The GitHub Actions run was cancelled or timed out before the dry run finished.',
    ),
  );
}

try {
  const status = await run();
  console.log(`\nThe scaffolder answered ${status}; the portal has the result`);
  await leave(0);
} catch (error) {
  // The first line is for the editor; the rest (backend output) stays here.
  await fail(
    `The template could not be tried out: ${error.message.split('\n')[0]}`,
    error.message,
  );
}
