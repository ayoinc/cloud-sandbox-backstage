import { Hono } from 'hono';
import { parseAllDocuments } from 'yaml';
import { requirePortalAdmin } from '../admin';
import { base64ToBytes } from '../encoding';
import { conflictError, HttpError, inputError, notFoundError } from '../errors';
import { isRecord, readJson } from '../json';
import { dispatchWorkflow } from '../scaffolder';
import type { AppEnv } from '../types';
import type { Entity, LocationRef } from './entity';

/**
 * Registered catalog locations (`/api/catalog/locations` and friends): what
 * the Register an existing component page calls.
 *
 * The catalog is processed in GitHub Actions, not here. Registering a
 * location checks the file enough to show what it holds, records it in the
 * `locations` table next to those registered by software templates, and
 * starts a catalog sync. The entities appear when that sync has finished.
 *
 * Only catalog files on github.com are read, with the Worker's own token.
 */
export const locationRoutes = new Hono<AppEnv>();

const SYNC_WORKFLOW = 'portal-sync.yml';
const DEFAULT_FILENAME = 'catalog-info.yaml';
const MAX_BODY_BYTES = 16 * 1024;
// How many leading path parts are tried as the branch name. A branch such
// as feature/x cannot be told from a directory in a blob address, and each
// try is a call to GitHub.
const MAX_REF_PARTS = 4;

const LOCATION_ANNOTATION = 'backstage.io/managed-by-location';
const ORIGIN_LOCATION_ANNOTATION = 'backstage.io/managed-by-origin-location';

const SUPPORTED_FILE =
  'Only catalog files on GitHub can be registered here: paste the address of the YAML file, such as https://github.com/<owner>/<repo>/blob/<branch>/catalog-info.yaml';
const SUPPORTED_REPOSITORY =
  'Only GitHub repositories can be looked through here: give https://github.com/<owner>/<repo>, or the address of the catalog file itself';

const encoder = new TextEncoder();
const decoder = new TextDecoder();

/** A location as the Backstage backend reports it. */
interface RegisteredLocation extends LocationRef {
  id: string;
  entityRef: string;
}

/**
 * The table has no id column: a location is known by its type and target.
 * The id given out is the hash Backstage names the location's own entity
 * with (`location:default/generated-<hash>`), so it is the same every time.
 */
async function describeLocation(
  type: string,
  target: string,
): Promise<RegisteredLocation> {
  const hash = await crypto.subtle.digest(
    'SHA-1',
    encoder.encode(`${type}:${target}`),
  );
  const id = [...new Uint8Array(hash)]
    .map(byte => byte.toString(16).padStart(2, '0'))
    .join('');
  return { id, type, target, entityRef: `location:default/generated-${id}` };
}

async function listLocations(db: D1Database): Promise<RegisteredLocation[]> {
  const { results } = await db
    .prepare('SELECT type, target FROM locations ORDER BY created_at, target')
    .all<LocationRef>();
  return Promise.all(
    results.map(({ type, target }) => describeLocation(type, target)),
  );
}

/** An id cannot be turned back into a target, so every row is looked at. */
async function locationById(
  db: D1Database,
  id: string,
): Promise<RegisteredLocation> {
  const location = (await listLocations(db)).find(item => item.id === id);
  if (!location) {
    throw notFoundError(`Found no location with ID ${id}`);
  }
  return location;
}

const isRegistered = async (db: D1Database, target: string) =>
  (await db
    .prepare(
      "SELECT 1 FROM locations WHERE type = 'url' AND target = ? LIMIT 1",
    )
    .bind(target)
    .first()) !== null;

/**
 * Starts a catalog sync, which is what makes a change to the registered
 * locations show in the catalog. Returns the reason if it did not start.
 */
async function startSync(env: Env): Promise<string | undefined> {
  const problem = await dispatchWorkflow(env, SYNC_WORKFLOW);
  if (problem) {
    console.warn(
      JSON.stringify({ message: 'Catalog sync not started', problem }),
    );
  }
  return problem;
}

interface GithubFile {
  text: string;
  /** The address of the file on github.com, with the branch it was read from. */
  url: string;
}

/**
 * Reads a file through the GitHub API with the Worker's token. Returns
 * `undefined` when GitHub has no such file, or does not show it to the token.
 */
async function readGithubFile(
  env: Env,
  repository: string,
  path: string,
  ref?: string,
): Promise<GithubFile | undefined> {
  if (!env.PORTAL_GITHUB_TOKEN) {
    throw new HttpError(
      503,
      'ServiceUnavailableError',
      'Files cannot be read from GitHub: the PORTAL_GITHUB_TOKEN secret is not set',
    );
  }
  const response = await fetch(
    `https://api.github.com/repos/${repository}/contents/${path}${
      ref === undefined ? '' : `?ref=${encodeURIComponent(ref)}`
    }`,
    {
      headers: {
        accept: 'application/vnd.github+json',
        authorization: `Bearer ${env.PORTAL_GITHUB_TOKEN}`,
        'user-agent': 'cloud-sandbox-portal',
        'x-github-api-version': '2022-11-28',
      },
    },
  );
  if (response.status === 404) {
    return undefined;
  }
  if (!response.ok) {
    const detail = await response
      .json<{ message?: string }>()
      .catch(() => undefined);
    throw new HttpError(
      502,
      'Error',
      `GitHub answered ${response.status}${
        detail?.message ? ` (${detail.message})` : ''
      } when asked for ${path} in ${repository}`,
    );
  }
  const file = await response.json<unknown>();
  if (!isRecord(file) || file.type !== 'file') {
    throw inputError(`${path} in ${repository} is not a file`);
  }
  // GitHub leaves the content out of files over 1 MB.
  if (
    file.encoding !== 'base64' ||
    typeof file.content !== 'string' ||
    typeof file.html_url !== 'string'
  ) {
    throw inputError(`${path} in ${repository} is too large to read`);
  }
  return {
    text: decoder.decode(base64ToBytes(file.content.replaceAll('\n', ''))),
    url: file.html_url,
  };
}

interface FileTarget {
  /** The target in the form it is stored and compared in. */
  target: string;
  /** `<owner>/<repo>` */
  repository: string;
  /** What follows `/blob/`: the branch, then the path, still URL-encoded. */
  parts: string[];
}

function parseFileTarget(target: unknown): FileTarget {
  const url =
    typeof target === 'string' && URL.canParse(target)
      ? new URL(target)
      : undefined;
  const match =
    url?.origin === 'https://github.com' &&
    !url.username &&
    !url.password &&
    !url.search &&
    !url.hash
      ? /^\/([\w.-]+\/[\w.-]+)\/blob\/(.+\.ya?ml)$/.exec(url.pathname)
      : null;
  const parts = match?.[2].split('/') ?? [];
  // A branch and a file at least. Wildcard targets, which the Backstage
  // backend expands into many files, are not read here.
  if (
    !url ||
    !match ||
    parts.length < 2 ||
    parts.some(part => part === '' || part.includes('*'))
  ) {
    throw inputError(SUPPORTED_FILE);
  }
  return { target: url.href, repository: match[1], parts };
}

async function readFileTarget(env: Env, file: FileTarget): Promise<string> {
  const tries = Math.min(file.parts.length - 1, MAX_REF_PARTS);
  for (let count = 1; count <= tries; count++) {
    const found = await readGithubFile(
      env,
      file.repository,
      file.parts.slice(count).join('/'),
      decodeURIComponent(file.parts.slice(0, count).join('/')),
    );
    if (found) {
      return found.text;
    }
  }
  throw notFoundError(
    `${file.target} was not found on GitHub, or the portal's GitHub token is not allowed to read it`,
  );
}

// The rules of the Backstage catalog model for the fields every entity has.
const isName = (value: unknown): value is string =>
  typeof value === 'string' &&
  value.length <= 63 &&
  /^([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9]$/.test(value);
const isDnsLabel = (value: unknown): value is string =>
  typeof value === 'string' &&
  value.length <= 63 &&
  /^[a-z0-9]+(?:-+[a-z0-9]+)*$/.test(value);
const isKind = (value: unknown): value is string =>
  typeof value === 'string' &&
  value.length <= 63 &&
  /^[a-zA-Z][a-z0-9A-Z]*$/.test(value);
function isApiVersion(value: unknown): value is string {
  const parts = typeof value === 'string' ? value.split('/') : [];
  const version = parts.pop() ?? '';
  return (
    parts.length <= 1 &&
    version.length <= 63 &&
    /^[a-z0-9A-Z]+$/.test(version) &&
    parts.every(
      group => group.length <= 253 && group.split('.').every(isDnsLabel),
    )
  );
}

/**
 * Reads the entities of a catalog file and checks the fields every entity
 * needs. The full check, against the schema of each kind, is made by the
 * Backstage backend when the catalog is synced.
 */
function parseEntities(text: string, target: string): Entity[] {
  const entities: Entity[] = [];
  for (const [index, document] of parseAllDocuments(text).entries()) {
    const where = `document ${index + 1} of ${target}`;
    if (document.errors.length) {
      throw inputError(`YAML error in ${where}: ${document.errors[0].message}`);
    }
    const value: unknown = document.toJS();
    if (value === null || value === undefined) {
      continue;
    }
    if (!isRecord(value)) {
      throw inputError(`Expected an entity in ${where}, found something else`);
    }
    const { apiVersion, kind, metadata } = value;
    if (!isApiVersion(apiVersion)) {
      throw inputError(
        `The entity in ${where} needs an apiVersion such as backstage.io/v1alpha1`,
      );
    }
    if (!isKind(kind)) {
      throw inputError(
        `The entity in ${where} needs a kind: a letter, then letters and digits, at most 63 characters`,
      );
    }
    if (!isRecord(metadata)) {
      throw inputError(`The ${kind} in ${where} has no metadata`);
    }
    if (!isName(metadata.name)) {
      throw inputError(
        `The ${kind} in ${where} needs a metadata.name of at most 63 characters from [a-z0-9A-Z-_.], starting and ending with a letter or digit`,
      );
    }
    const namespace = metadata.namespace ?? 'default';
    if (!isDnsLabel(namespace)) {
      throw inputError(
        `The ${kind} "${metadata.name}" in ${where} has an invalid metadata.namespace: use at most 63 lower-case letters, digits and dashes`,
      );
    }
    const annotations = metadata.annotations ?? {};
    if (
      !isRecord(annotations) ||
      !Object.values(annotations).every(item => typeof item === 'string')
    ) {
      throw inputError(
        `The ${kind} "${metadata.name}" in ${where} needs metadata.annotations to be a map of text values`,
      );
    }
    entities.push({
      ...value,
      apiVersion,
      kind,
      metadata: {
        ...metadata,
        name: metadata.name,
        namespace,
        annotations: {
          ...(annotations as Record<string, string>),
          [LOCATION_ANNOTATION]: `url:${target}`,
          [ORIGIN_LOCATION_ANNOTATION]: `url:${target}`,
        },
      },
    });
  }
  if (!entities.length) {
    throw inputError(`${target} holds no entities`);
  }
  return entities;
}

locationRoutes.post('/locations', async c => {
  await requirePortalAdmin(c);
  const body = await readJson(c, MAX_BODY_BYTES);
  if (!isRecord(body) || (body.type ?? 'url') !== 'url') {
    throw inputError('Registered locations must be of type "url"');
  }
  const file = parseFileTarget(body.target);
  const { target } = file;
  const entities = parseEntities(await readFileTarget(c.env, file), target);
  const location = await describeLocation('url', target);

  if (['true', '1', 'yes', 'y', 'on'].includes(c.req.query('dryRun') ?? '')) {
    return c.json(
      { location, entities, exists: await isRegistered(c.env.DB, target) },
      201,
    );
  }

  // The statement of the pipeline's POST /locations (pipeline.ts), which
  // records what software templates register.
  const { meta } = await c.env.DB.prepare(
    'INSERT INTO locations (type, target) VALUES (?, ?) ON CONFLICT DO NOTHING',
  )
    .bind('url', target)
    .run();
  if (!meta.changes && c.req.query('onConflict') !== 'refresh') {
    throw conflictError(`Location url:${target} already exists`);
  }
  // The registration stands if the sync cannot be started: the next one,
  // scheduled or started by a push, reads it. As on the Backstage backend,
  // no entities are returned: there are none before the catalog has synced.
  await startSync(c.env);
  return c.json({ location, entities: [] }, 201);
});

locationRoutes.get('/locations', async c =>
  c.json((await listLocations(c.env.DB)).map(data => ({ data }))),
);

locationRoutes.get('/locations/by-entity/:kind/:namespace/:name', async c => {
  const { kind, namespace, name } = c.req.param();
  const entityRef = `${kind}:${namespace}/${name}`.toLowerCase();
  const location = (await listLocations(c.env.DB)).find(
    item => item.entityRef === entityRef,
  );
  if (!location) {
    throw notFoundError(`Found no location with entity ref ${entityRef}`);
  }
  return c.json(location);
});

locationRoutes.get('/locations/:id', async c =>
  c.json(await locationById(c.env.DB, c.req.param('id'))),
);

locationRoutes.delete('/locations/:id', async c => {
  await requirePortalAdmin(c);
  const { type, target } = await locationById(c.env.DB, c.req.param('id'));
  await c.env.DB.prepare('DELETE FROM locations WHERE type = ? AND target = ?')
    .bind(type, target)
    .run();
  // The entities stay in the catalog until a sync has run without them.
  await startSync(c.env);
  return c.body(null, 204);
});

/**
 * The Backstage backend reads one entity again. Here the whole catalog is
 * synced, which is the only way an entity is read at all.
 */
locationRoutes.post('/refresh', async c => {
  await requirePortalAdmin(c);
  const body = await readJson(c, MAX_BODY_BYTES);
  if (!isRecord(body) || typeof body.entityRef !== 'string') {
    throw inputError('A refresh needs an entityRef');
  }
  const problem = await startSync(c.env);
  if (problem) {
    throw new HttpError(
      503,
      'ServiceUnavailableError',
      `The catalog sync could not be started: ${problem}`,
    );
  }
  return c.body(null, 200);
});

/**
 * Looks for a catalog file at the root of a repository's default branch.
 * Proposing entities for a repository that has none, which the page would
 * turn into a pull request, is not done here: `generateEntities` is empty.
 */
locationRoutes.post('/analyze-location', async c => {
  await requirePortalAdmin(c);
  const body = await readJson(c, MAX_BODY_BYTES);
  const location = isRecord(body) ? body.location : undefined;
  const target = isRecord(location) ? location.target : undefined;
  const url =
    typeof target === 'string' && URL.canParse(target)
      ? new URL(target)
      : undefined;
  const repository =
    url?.origin === 'https://github.com'
      ? /^\/([\w.-]+\/[\w.-]+?)(\.git)?\/?$/.exec(url.pathname)?.[1]
      : undefined;
  if (!repository) {
    throw inputError(SUPPORTED_REPOSITORY);
  }
  const filename =
    isRecord(body) && body.catalogFilename !== undefined
      ? body.catalogFilename
      : DEFAULT_FILENAME;
  if (typeof filename !== 'string' || !/^[\w.-]+\.ya?ml$/.test(filename)) {
    throw inputError('catalogFilename must be the name of a YAML file');
  }
  const file = await readGithubFile(c.env, repository, filename);
  if (!file) {
    return c.json({ existingEntityFiles: [], generateEntities: [] });
  }
  // The address GitHub gives names the default branch, so it is the target
  // POST /locations is then asked to register.
  const found = parseFileTarget(file.url);
  const registered = await isRegistered(c.env.DB, found.target);
  return c.json({
    existingEntityFiles: parseEntities(file.text, found.target).map(entity => ({
      isRegistered: registered,
      location: { type: 'url', target: found.target },
      entity,
    })),
    generateEntities: [],
  });
});
