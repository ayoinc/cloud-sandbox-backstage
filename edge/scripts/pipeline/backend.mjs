// Starts, calls and stops the pipeline backend (packages/backend/src/pipeline.ts).
import { spawn } from 'node:child_process';
import { generateKeyPairSync, randomBytes } from 'node:crypto';
import { closeSync, openSync, readFileSync } from 'node:fs';
import { mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { createServer } from 'node:net';
import { join, relative, resolve, sep } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';
import { parse, stringify } from 'yaml';
import { repoRoot } from './settings.mjs';

const BACKEND_DIR = join(repoRoot, 'packages/backend');
const RUN_CONFIG = 'app-config.run.yaml';
const PUBLIC_KEY = 'plugin-auth.public.pem';
const PRIVATE_KEY = 'plugin-auth.private.pem';
const BACKEND_LOG = 'backend.log';
const START_TIMEOUT_MS = 180_000;
const STOP_TIMEOUT_MS = 10_000;

/**
 * Creates the data directory, or empties it of what an earlier run left, so
 * the catalog is always processed from nothing. Only files this pipeline
 * writes are removed: the directory can be set to anywhere.
 */
export async function prepareDataDir(dataDir) {
  await mkdir(dataDir, { recursive: true });
  for (const name of await readdir(dataDir)) {
    if (
      /\.sqlite(-journal)?$/.test(name) ||
      [RUN_CONFIG, PUBLIC_KEY, PRIVATE_KEY, BACKEND_LOG, 'techdocs'].includes(
        name,
      )
    ) {
      await rm(join(dataDir, name), { recursive: true, force: true });
    }
  }
}

/**
 * Writes the second config file of a run, next to app-config.pipeline.yaml,
 * and returns the catalog locations it lists.
 *
 * It tells the pipeline backend which entity files to read. Rules and
 * locations are taken from app-config.yaml, so this backend reads exactly
 * what the main one does. In GitHub Actions the files of this repository are
 * read from GitHub instead of the checkout: entities then carry the
 * repository address as their source, which is what "View source" links and
 * relative documentation paths are built from. `registered` are the locations
 * of repositories created from templates, kept by the portal.
 *
 * It also gives the backend a key pair for the tokens its plugins call each
 * other with. By default those keys are kept in the database, and SQLite
 * allows one connection: when the catalog finds two files claiming the same
 * entity it reports that from inside a transaction, the report needs a token,
 * the token needs the database, and processing stops for a minute each time.
 */
export async function writeRunConfig(dataDir, { github, registered }) {
  const { publicKey, privateKey } = generateKeyPairSync('ec', {
    namedCurve: 'prime256v1',
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
  });
  await writeFile(join(dataDir, PUBLIC_KEY), publicKey);
  await writeFile(join(dataDir, PRIVATE_KEY), privateKey, { mode: 0o600 });

  const { catalog } = parse(
    await readFile(join(repoRoot, 'app-config.yaml'), 'utf8'),
  );
  const configured = catalog.locations.map(location => {
    if (location.type !== 'file') {
      return location;
    }
    // File targets in app-config.yaml are relative to the backend package.
    const file = resolve(BACKEND_DIR, location.target);
    if (!github) {
      return { ...location, target: file };
    }
    const path = relative(repoRoot, file).split(sep).join('/');
    return {
      ...location,
      type: 'url',
      target: `${github.serverUrl}/${github.repository}/blob/${github.refName}/${path}`,
    };
  });
  const locations = [
    ...new Map(
      [...configured, ...registered].map(location => [
        `${location.type}:${location.target}`,
        location,
      ]),
    ).values(),
  ];
  await writeFile(
    join(dataDir, RUN_CONFIG),
    stringify({
      backend: {
        auth: {
          pluginKeyStore: {
            type: 'static',
            static: {
              keys: [
                {
                  keyId: 'pipeline-run',
                  publicKeyFile: join(dataDir, PUBLIC_KEY),
                  privateKeyFile: join(dataDir, PRIVATE_KEY),
                },
              ],
            },
          },
        },
      },
      catalog: { rules: catalog.rules, locations },
    }),
  );
  return locations;
}

/** Everything the backend on this data directory has printed so far. */
export function readBackendLog(dataDir) {
  try {
    return readFileSync(join(dataDir, BACKEND_LOG), 'utf8');
  } catch {
    return '';
  }
}

/** The end of the backend's output, for error messages. */
export function backendLogTail(dataDir) {
  return readBackendLog(dataDir).trimEnd().split('\n').slice(-40).join('\n');
}

/** Fails when the port is taken; `variable` is what changes the port. */
export async function assertPortFree(port, variable) {
  await new Promise((free, busy) => {
    const probe = createServer();
    probe.once('error', () =>
      busy(
        new Error(`Port ${port} is in use. Set ${variable} to a free port.`),
      ),
    );
    probe.listen(port, '127.0.0.1', () => probe.close(free));
  });
}

/**
 * Starts the pipeline backend on the data directory and waits until it
 * answers. The directory must hold the config written by `writeRunConfig`.
 * Output goes to backend.log in the data directory.
 *
 * `backstage-cli package start` cannot be used: for a backend package it
 * always runs src/index.ts. This is the command it runs underneath, without
 * the file watcher.
 */
export async function startBackend({ dataDir, githubToken }) {
  const port = Number(process.env.PIPELINE_BACKEND_PORT || 7107);
  await assertPortFree(port, 'PIPELINE_BACKEND_PORT');

  const token = randomBytes(24).toString('base64url');
  const log = openSync(join(dataDir, BACKEND_LOG), 'w');
  const child = spawn(
    process.execPath,
    [
      '--enable-source-maps',
      '--require',
      '@backstage/cli/config/nodeTransform.cjs',
      'src/pipeline.ts',
      '--config',
      join(repoRoot, 'app-config.pipeline.yaml'),
      '--config',
      join(dataDir, RUN_CONFIG),
    ],
    {
      cwd: BACKEND_DIR,
      env: {
        ...process.env,
        PIPELINE_DATA_DIR: dataDir,
        PIPELINE_BACKEND_PORT: String(port),
        PIPELINE_BACKEND_TOKEN: token,
        ...(githubToken && { PORTAL_GITHUB_TOKEN: githubToken }),
      },
      stdio: ['ignore', log, log],
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
  // Never leave the backend running behind a script that has ended.
  process.once('exit', () => child.kill('SIGKILL'));

  const stop = async () => {
    if (exit) {
      return;
    }
    child.kill('SIGTERM');
    const forced = setTimeout(() => child.kill('SIGKILL'), STOP_TIMEOUT_MS);
    await exited;
    clearTimeout(forced);
  };

  const url = `http://127.0.0.1:${port}`;
  const deadline = Date.now() + START_TIMEOUT_MS;
  for (;;) {
    if (exit) {
      throw new Error(
        `The pipeline backend stopped while starting (exit code ${
          exit.code
        }). Last output:\n${backendLogTail(dataDir)}`,
      );
    }
    if (Date.now() > deadline) {
      await stop();
      throw new Error(
        `The pipeline backend did not start within ${
          START_TIMEOUT_MS / 1000
        } seconds. Last output:\n${backendLogTail(dataDir)}`,
      );
    }
    const ready = await fetch(`${url}/.backstage/health/v1/readiness`).then(
      response => response.ok,
      () => false,
    );
    if (ready) {
      return { url, token, stop };
    }
    await sleep(500);
  }
}

/**
 * Calls the pipeline backend with its static token and returns the parsed
 * JSON. A failed call throws an error carrying `status` and the parsed `body`.
 */
export async function backendRequest(
  backend,
  path,
  { method = 'GET', json } = {},
) {
  const response = await fetch(`${backend.url}${path}`, {
    method,
    headers: {
      authorization: `Bearer ${backend.token}`,
      ...(json !== undefined && { 'content-type': 'application/json' }),
    },
    body: json === undefined ? undefined : JSON.stringify(json),
  });
  const text = await response.text();
  let body;
  try {
    body = text ? JSON.parse(text) : undefined;
  } catch {
    body = undefined;
  }
  if (!response.ok) {
    throw Object.assign(
      new Error(
        `The pipeline backend answered ${
          response.status
        } to ${method} ${path}: ${body?.error?.message ?? text.slice(0, 500)}`,
      ),
      { status: response.status, body },
    );
  }
  return body;
}
