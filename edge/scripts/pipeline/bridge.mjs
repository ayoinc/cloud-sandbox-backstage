// Gives a pipeline script the portal to talk to.
import { spawn } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { closeSync, openSync, readFileSync } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';
import { assertPortFree } from './backend.mjs';
import { repoRoot } from './settings.mjs';

const EDGE_DIR = join(repoRoot, 'edge');
const BRIDGE_CONFIG = 'wrangler.pipeline.jsonc';
const BRIDGE_LOG = 'portal-bridge.log';
const BRIDGE_STATE = 'portal-bridge-state';
const START_TIMEOUT_MS = 120_000;
const STOP_TIMEOUT_MS = 10_000;

const logTail = dataDir => {
  try {
    return readFileSync(join(dataDir, BRIDGE_LOG), 'utf8')
      .trimEnd()
      .split('\n')
      .slice(-40)
      .join('\n');
  } catch {
    return '';
  }
};

/**
 * Starts the portal Worker on this machine with `wrangler dev`, bound to the
 * deployed database and bucket (wrangler.pipeline.jsonc), and waits until it
 * answers from the database.
 *
 * The deployed portal cannot be called from GitHub Actions directly:
 * Cloudflare answers a runner's requests to the public address with a
 * challenge page. This way the same /api/pipeline code runs here and reaches
 * the data through Cloudflare's API, which is not behind that protection.
 * The token it accepts is made for this run and never leaves the machine.
 */
async function startBridge({ cloudflare, dataDir }) {
  const port = Number(process.env.PIPELINE_BRIDGE_PORT || 8797);
  await assertPortFree(port, 'PIPELINE_BRIDGE_PORT');
  await mkdir(dataDir, { recursive: true });

  const wrangler = join(
    dirname(createRequire(import.meta.url).resolve('wrangler/package.json')),
    'bin/wrangler.js',
  );
  const token = randomBytes(24).toString('base64url');
  const log = openSync(join(dataDir, BRIDGE_LOG), 'w');
  const child = spawn(
    process.execPath,
    [
      wrangler,
      'dev',
      '--config',
      BRIDGE_CONFIG,
      '--ip',
      '127.0.0.1',
      '--port',
      String(port),
      '--inspector-port',
      '0',
      '--persist-to',
      join(dataDir, BRIDGE_STATE),
      '--show-interactive-dev-session',
      'false',
      '--var',
      `PIPELINE_TOKEN:${token}`,
    ],
    {
      cwd: EDGE_DIR,
      env: {
        ...process.env,
        CLOUDFLARE_API_TOKEN: cloudflare.apiToken,
        ...(cloudflare.accountId && {
          CLOUDFLARE_ACCOUNT_ID: cloudflare.accountId,
        }),
        WRANGLER_SEND_METRICS: 'false',
      },
      stdio: ['ignore', log, log],
      // Its own process group: wrangler runs the Worker in a child of its
      // own, which has to go when wrangler is killed.
      detached: true,
    },
  );
  closeSync(log);

  let exit;
  const exited = new Promise(done => {
    child.once('exit', (code, signal) => {
      exit = { code, signal };
      done();
    });
  });
  const killGroup = () => {
    try {
      process.kill(-child.pid, 'SIGKILL');
    } catch {
      // Already gone.
    }
  };
  // Never leave the Worker running behind a script that has ended.
  process.once('exit', killGroup);

  const stop = async () => {
    if (exit) {
      return;
    }
    child.kill('SIGTERM');
    const forced = setTimeout(killGroup, STOP_TIMEOUT_MS);
    await exited;
    clearTimeout(forced);
  };

  const url = `http://127.0.0.1:${port}`;
  const deadline = Date.now() + START_TIMEOUT_MS;
  let lastAnswer = 'no answer';
  for (;;) {
    if (exit) {
      throw new Error(
        `The portal Worker stopped while starting (exit code ${
          exit.code
        }). Last output:\n${logTail(dataDir)}`,
      );
    }
    if (Date.now() > deadline) {
      await stop();
      throw new Error(
        `The portal Worker could not reach the deployed database within ${
          START_TIMEOUT_MS / 1000
        } seconds (${lastAnswer}). Check that CLOUDFLARE_API_TOKEN may edit D1, R2 and Workers scripts. Last output:\n${logTail(
          dataDir,
        )}`,
      );
    }
    // A database read: answers only once the remote connection works.
    const ready = await fetch(`${url}/api/pipeline/locations`, {
      headers: { authorization: `Bearer ${token}` },
    }).then(
      response => {
        lastAnswer = `last answer ${response.status}`;
        return response.ok;
      },
      () => false,
    );
    if (ready) {
      return { url, token, stop };
    }
    await sleep(500);
  }
}

/**
 * Returns the portal the script should call: `{ url, token, name, stop }`.
 *
 * With PORTAL_URL it is that address, called directly: a Worker running
 * locally under `yarn dev`. Without it, it is the deployed portal, reached
 * through a Worker started here with the Cloudflare credentials.
 */
export async function connectPortal({ portal, cloudflare }, dataDir) {
  if (portal) {
    return { ...portal, name: portal.url, stop: async () => {} };
  }
  const bridge = await startBridge({ cloudflare, dataDir });
  return { ...bridge, name: 'the deployed portal, through Cloudflare' };
}
