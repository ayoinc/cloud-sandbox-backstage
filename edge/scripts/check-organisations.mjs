// Checks that the Worker answers organisation requests exactly like the Node
// backend. Both run the same cases, packages/backend/src/organisations/
// cases.json: the Node backend in its unit tests, the Worker here. How a case
// is run is written down in packages/backend/src/__tests__/
// organisations.test.ts; this file follows the same rules.
//
// Run it against a Worker started with `yarn dev`, with every migration
// applied to its local database (`yarn db:migrate:local`). It creates
// organisations in that Worker's database and deletes them again, signing
// its callers' tokens itself, so it refuses any Worker that is not on this
// machine. Do not run it against a local Worker bound to the deployed
// database (wrangler.pipeline.jsonc).
//
// The cases need one portal administrator. For as long as it runs, this
// script keeps a row for its own (user:default/organisations-check-admin)
// in the local database's `branding_admins`, written with `wrangler d1
// execute --local`, and removes it when it is done. Nobody can sign in as
// that user: only this script, holding the session secret, makes its token.
//
//   EDGE_URL        (default http://localhost:8787) the Worker
//   SESSION_SECRET  (default: the one in .dev.vars) signs the callers' tokens
//   EDGE_DATABASE   (default cloud-sandbox) the D1 database in wrangler.jsonc
//   PERSIST_TO      where the Worker keeps its local state, when it was
//                   started with `--persist-to`
import { execFileSync } from 'node:child_process';
import { createHmac, randomInt } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isDeepStrictEqual } from 'node:util';

const EDGE = process.env.EDGE_URL ?? 'http://localhost:8787';
if (!['localhost', '127.0.0.1', '[::1]'].includes(new URL(EDGE).hostname)) {
  console.error(
    `${EDGE} is not on this machine. This check writes to the database of the Worker it calls.`,
  );
  process.exit(1);
}
const GUEST_USER = 'user:development/guest';
const ADMIN = 'user:default/organisations-check-admin';
const CALLERS = { admin: ADMIN, guest: GUEST_USER };
const PEOPLE = ['jane', 'kim', 'sam'];
const FILES = {
  // A PNG of one pixel.
  png: Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    'base64',
  ),
  svg: Buffer.from(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>',
  ),
  text: Buffer.from('hello'),
};

const read = path => readFileSync(new URL(path, import.meta.url), 'utf8');

const secret =
  process.env.SESSION_SECRET ??
  /^SESSION_SECRET=(.*)$/m
    .exec(read('../.dev.vars'))?.[1]
    .replace(/^"|"$/g, '');
if (!secret) {
  console.error('Set SESSION_SECRET, or add it to edge/.dev.vars.');
  process.exit(1);
}

/** A user token as the Worker issues them at sign-in (edge/src/auth.ts). */
function tokenFor(userEntityRef) {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = [
    { typ: 'vnd.backstage.user', alg: 'HS256' },
    {
      iss: `${EDGE}/api/auth`,
      sub: userEntityRef,
      ent: [userEntityRef],
      aud: 'backstage',
      iat: now,
      exp: now + 600,
    },
  ]
    .map(part => Buffer.from(JSON.stringify(part)).toString('base64url'))
    .join('.');
  const signature = createHmac('sha256', secret)
    .update(unsigned)
    .digest('base64url');
  return `${unsigned}.${signature}`;
}

/** `value` with every placeholder in every string of it filled in. */
function fill(value, run) {
  if (typeof value === 'string') {
    return PEOPLE.reduce(
      (text, person) =>
        text.replaceAll(`{${person}}`, `user:default/${person}-${run}`),
      value.replaceAll('{run}', run).replaceAll('{admin}', ADMIN),
    );
  }
  if (Array.isArray(value)) {
    return value.map(item => fill(item, run));
  }
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, fill(item, run)]),
    );
  }
  return value;
}

/** Whether `seen` is what a case expects: "<any>" is anything but null. */
function matches(wanted, seen) {
  if (wanted === '<any>') {
    return seen !== null && seen !== undefined;
  }
  if (Array.isArray(wanted)) {
    return (
      Array.isArray(seen) &&
      seen.length === wanted.length &&
      wanted.every((item, index) => matches(item, seen[index]))
    );
  }
  if (wanted && typeof wanted === 'object') {
    return (
      Boolean(seen) &&
      typeof seen === 'object' &&
      !Array.isArray(seen) &&
      isDeepStrictEqual(Object.keys(wanted).sort(), Object.keys(seen).sort()) &&
      Object.keys(wanted).every(key => matches(wanted[key], seen[key]))
    );
  }
  return wanted === seen;
}

// wrangler as this package has it, run with the node that runs this.
const wranglerPackage = createRequire(import.meta.url).resolve(
  'wrangler/package.json',
);
const WRANGLER = join(
  dirname(wranglerPackage),
  JSON.parse(readFileSync(wranglerPackage, 'utf8')).bin.wrangler,
);

/** Runs one statement on the Worker's local database. */
function onLocalDatabase(sql) {
  execFileSync(
    process.execPath,
    [
      WRANGLER,
      'd1',
      'execute',
      process.env.EDGE_DATABASE ?? 'cloud-sandbox',
      '--local',
      ...(process.env.PERSIST_TO
        ? ['--persist-to', process.env.PERSIST_TO]
        : []),
      '--command',
      sql,
    ],
    { cwd: fileURLToPath(new URL('..', import.meta.url)), stdio: 'pipe' },
  );
}

/** Makes this script's administrator one, or stops being one. */
function setAdmin(present) {
  // Its own row only: told apart by who added it.
  onLocalDatabase(
    `DELETE FROM branding_admins WHERE entity_ref = '${ADMIN}' AND added_by = 'organisations-check'`,
  );
  if (present) {
    onLocalDatabase(
      `INSERT INTO branding_admins (entity_ref, type, added_by) VALUES ('${ADMIN}', 'user', 'organisations-check')`,
    );
  }
}

/** Runs one case; returns what went wrong, or nothing. */
async function runCase({ steps }) {
  const run = Array.from({ length: 6 }, () =>
    String.fromCharCode(97 + randomInt(26)),
  ).join('');
  // The addresses the case's organisations had, to be removed again
  // whatever happens: the administrator can remove any.
  const created = [];
  try {
    return await runSteps(steps, run, created);
  } finally {
    for (const slug of created) {
      await fetch(`${EDGE}/api/organisations/${slug}`, {
        method: 'DELETE',
        headers: { authorization: `Bearer ${tokenFor(ADMIN)}` },
      });
    }
  }
}

async function runSteps(steps, run, created) {
  let version = '';

  for (const [index, step] of steps.entries()) {
    const user =
      step.as && (CALLERS[step.as] ?? `user:default/${step.as}-${run}`);
    const headers = {};
    let body;
    if (user) {
      headers.authorization = `Bearer ${tokenFor(user)}`;
    }
    if (step.file) {
      body = FILES[step.file];
      headers['content-type'] = step.contentType ?? '';
    } else if (step.json !== undefined) {
      body = JSON.stringify(fill(step.json, run));
      headers['content-type'] = 'application/json';
    }
    const query = step.query?.replaceAll('{v}', version);
    const address = `${fill(step.path, run)}${query ? `?${query}` : ''}`;

    const response = await fetch(`${EDGE}/api/organisations${address}`, {
      method: step.method,
      headers,
      body,
    });
    const text = await response.text();
    const isJson = response.headers.get('content-type')?.includes('json');
    const answer = isJson && text ? JSON.parse(text) : undefined;
    const where = `step ${index + 1}: ${step.method} ${address} as ${step.as}`;

    if (response.status !== step.status) {
      return `${where}\n    answered ${response.status}, expected ${
        step.status
      }: ${text.slice(0, 300)}`;
    }
    if (step.body !== undefined && !matches(fill(step.body, run), answer)) {
      return `${where}\n    answered ${text.slice(
        0,
        600,
      )}\n    expected ${JSON.stringify(fill(step.body, run))}`;
    }
    for (const [key, items] of Object.entries(fill(step.has ?? {}, run))) {
      const list = answer?.[key];
      const missing = items.find(
        item => !Array.isArray(list) || !list.some(one => matches(item, one)),
      );
      if (missing) {
        return `${where}\n    ${key} in the answer ${text.slice(
          0,
          600,
        )}\n    does not hold ${JSON.stringify(missing)}`;
      }
    }
    for (const [name, value] of Object.entries(step.headers ?? {})) {
      if (response.headers.get(name) !== value) {
        return `${where}\n    ${name}: ${response.headers.get(
          name,
        )}, expected ${value}`;
      }
    }

    // Where it was made, and where an owner moved it to.
    if (
      ['POST', 'PATCH'].includes(step.method) &&
      response.ok &&
      typeof answer?.slug === 'string' &&
      !created.includes(answer.slug)
    ) {
      created.push(answer.slug);
    }
    const logo = answer?.logoFullUrl ?? answer?.logoIconUrl;
    if (typeof logo === 'string') {
      version = new URLSearchParams(logo.split('?')[1]).get('v') ?? '';
    }
  }
  return undefined;
}

const cases = JSON.parse(
  read('../../packages/backend/src/organisations/cases.json'),
);
let failed = 0;
try {
  setAdmin(true);
} catch (error) {
  console.error(
    `Could not add the check's portal administrator to the local database. Has \`yarn db:migrate:local\` been run?\n${
      error.stderr ?? error
    }`,
  );
  process.exit(1);
}
try {
  for (const one of cases) {
    const problem = await runCase(one);
    console.log(`${problem ? 'FAIL' : 'ok  '} ${one.name}`);
    if (problem) {
      failed += 1;
      console.log(`  ${problem}`);
    }
  }
} finally {
  setAdmin(false);
}
console.log(
  failed
    ? `\n${failed} of ${cases.length} cases differ from the Node backend.`
    : `\nAll ${cases.length} cases are answered as the Node backend answers them.`,
);
process.exit(failed ? 1 : 0);
