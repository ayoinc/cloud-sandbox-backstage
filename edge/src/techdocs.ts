import { Hono, type MiddlewareHandler } from 'hono';
import { deleteCookie, getCookie, setCookie } from 'hono/cookie';
import { getMimeType } from 'hono/utils/mime';
import { requireUser, signInFromHeader, signToken, verifyToken } from './auth';
import {
  parseLocationRef,
  sourceLocation,
  type Entity,
  type LocationRef,
} from './catalog/entity';
import { entityByName } from './catalog/queries';
import { authenticationError, notFoundError } from './errors';
import { rawJson } from './json';
import type { AppEnv } from './types';

/**
 * The Backstage TechDocs API (`/api/techdocs`). Documentation is built by
 * the pipeline and stored in R2 under `sites/<siteId>/`; the `techdocs_sites`
 * table says which site belongs to an entity.
 *
 * Mounted ahead of the Worker's user check because it does its own: every
 * route needs a signed-in user, and files under `/static` also accept the
 * docs cookie, since a page's images cannot send an Authorization header.
 */
export const techdocsRoutes = new Hono<AppEnv>();

// The same cookie protocol as the Backstage backend, with the cookie limited
// to this API's path.
const COOKIE_ROUTE = '/.backstage/auth/v1/cookie';
const COOKIE_NAME = 'backstage-auth';
const COOKIE_SCOPE = '/api/techdocs';
const COOKIE_AUDIENCE = 'cloud-sandbox-techdocs';
const COOKIE_RENEWAL_SECONDS = 300;

const STATIC_ROOT = '/static/docs/';
const PLAIN_TEXT = 'text/plain; charset=utf-8';

interface EntityParams {
  namespace: string;
  kind: string;
  name: string;
}

const entityRef = ({ kind, namespace, name }: EntityParams) =>
  `${kind}:${namespace}/${name}`.toLowerCase();

/**
 * A file of the documentation site published for an entity, or `null`. Has
 * no body when the caller's copy (`ifNoneMatch`) is still current.
 */
async function siteFile(
  env: Env,
  ref: string,
  path: string,
  ifNoneMatch?: string,
) {
  const siteId = await env.DB.prepare(
    'SELECT site_id FROM techdocs_sites WHERE entity_ref = ?',
  )
    .bind(ref)
    .first<string>('site_id');
  return siteId
    ? env.TECHDOCS.get(`sites/${siteId}/${path}`, {
        onlyIf: new Headers(
          ifNoneMatch ? { 'if-none-match': ifNoneMatch } : {},
        ),
      })
    : null;
}

// Clearing the cookie needs no sign-in, as with the Backstage backend.
techdocsRoutes.delete(COOKIE_ROUTE, c => {
  deleteCookie(c, COOKIE_NAME, { path: COOKIE_SCOPE });
  return c.body(null, 204);
});

const requireReader: MiddlewareHandler<AppEnv> = async (c, next) => {
  const cookie =
    ['GET', 'HEAD'].includes(c.req.method) && !c.req.header('authorization')
      ? getCookie(c, COOKIE_NAME)
      : undefined;
  if (!cookie) {
    await signInFromHeader(c);
  } else if (
    !(await verifyToken(c.env.SESSION_SECRET, COOKIE_AUDIENCE, cookie))
  ) {
    throw authenticationError('Invalid or expired cookie');
  }
  await next();
};

/**
 * The content type a docs file is sent with. Like the Backstage publishers,
 * anything a browser would run as a page (HTML, SVG, XML) goes out as plain
 * text: the reader fetches pages as text and sanitises them, and a docs file
 * opened on its own must not run with the portal's origin.
 */
function contentType(path: string, stored: string | undefined): string {
  const name = path.slice(path.lastIndexOf('/') + 1);
  const extension = name.includes('.') ? name.slice(name.lastIndexOf('.')) : '';
  const type = stored ?? getMimeType(name) ?? PLAIN_TEXT;
  return /htm|xml|svg|appcache|manifest|mathml|owl|rdf|rng|vtt|xht|xsd|xsl/i.test(
    extension,
  ) || /html|xml|multipart|cache-manifest|octet-stream/i.test(type)
    ? PLAIN_TEXT
    : type;
}

techdocsRoutes.use('/static/*', requireReader);

techdocsRoutes.get(`${STATIC_ROOT}*`, async c => {
  // Read from the URL as sent: each part is decoded exactly once.
  const { pathname } = new URL(c.req.url);
  const parts = pathname
    .slice(pathname.indexOf(STATIC_ROOT) + STATIC_ROOT.length)
    .split('/');
  let decoded: string[];
  try {
    decoded = parts.map(decodeURIComponent);
  } catch {
    throw notFoundError('File not found');
  }
  const [namespace, kind, name, ...rest] = decoded;
  // A directory is served by its index page.
  const file =
    rest.at(-1) === '' || !rest.length
      ? [...rest.slice(0, -1), 'index.html']
      : rest;
  if (
    !namespace ||
    !kind ||
    !name ||
    file.some(
      part => !part || part === '.' || part === '..' || /[/\\]/.test(part),
    )
  ) {
    throw notFoundError('File not found');
  }
  const ref = entityRef({ namespace, kind, name });
  const path = file.join('/');
  const object = await siteFile(
    c.env,
    ref,
    path,
    c.req.header('if-none-match'),
  );
  if (!object) {
    throw notFoundError(`${path} is not in the documentation of ${ref}`);
  }
  const headers = {
    'content-type': contentType(path, object.httpMetadata?.contentType),
    'x-content-type-options': 'nosniff',
    etag: object.httpEtag,
    // Kept by the browser only, and checked against the server before each
    // use, so sign-in is enforced and a rebuilt site shows at once.
    'cache-control': 'private, no-cache',
  };
  return 'body' in object
    ? new Response(object.body, { headers })
    : new Response(null, { status: 304, headers });
});

techdocsRoutes.use('*', requireUser);

techdocsRoutes.get(COOKIE_ROUTE, async c => {
  const user = c.get('user').userEntityRef;
  const now = Math.floor(Date.now() / 1000);
  const existing = getCookie(c, COOKIE_NAME);
  const claims = existing
    ? await verifyToken(c.env.SESSION_SECRET, COOKIE_AUDIENCE, existing)
    : undefined;
  let expiresAt = Number(claims?.exp);
  if (claims?.sub !== user || expiresAt - now < COOKIE_RENEWAL_SECONDS) {
    // The cookie lasts as long as the token that asked for it.
    expiresAt = c.get('tokenExpiresAt');
    setCookie(
      c,
      COOKIE_NAME,
      await signToken(
        c.env.SESSION_SECRET,
        COOKIE_AUDIENCE,
        expiresAt - now,
        { sub: user },
        'vnd.backstage.limited-user',
      ),
      {
        httpOnly: true,
        secure: new URL(c.req.url).protocol === 'https:',
        sameSite: 'Lax',
        path: COOKIE_SCOPE,
        expires: new Date(expiresAt * 1000),
      },
    );
  }
  return c.json({ expiresAt: new Date(expiresAt * 1000).toISOString() });
});

techdocsRoutes.get('/metadata/techdocs/:namespace/:kind/:name', async c => {
  const ref = entityRef(c.req.param());
  const metadata = await siteFile(c.env, ref, 'techdocs_metadata.json');
  if (!metadata || !('body' in metadata)) {
    throw notFoundError(`Unable to get metadata for '${ref}'`);
  }
  return rawJson(metadata.body);
});

/** Resolves `child` inside the directory `base`, or not at all if it leaves it. */
function childPath(base: string, child: string): string | undefined {
  if (child.startsWith('/')) {
    return undefined;
  }
  const parts = base.split('/');
  const depth = parts.length;
  for (const part of child.split('/')) {
    if (part === '..') {
      if (parts.length === depth) {
        return undefined;
      }
      parts.pop();
    } else if (part && part !== '.') {
      parts.push(part);
    }
  }
  return parts.join('/');
}

/**
 * Resolves a docs directory against the URL of the entity's source. GitHub
 * is the one integration this deployment has, so its rules apply: a leading
 * slash means the repository root, and the result browses the tree.
 */
function resolveSourceUrl(directory: string, base: string): string {
  if (URL.canParse(directory)) {
    return directory;
  }
  const resolved = new URL(base);
  resolved.hash = '';
  if (directory.startsWith('/')) {
    const root =
      /^\/[^/]+\/[^/]+\/(?:blob|tree|edit)\/[^/]+/.exec(
        resolved.pathname,
      )?.[0] ?? '';
    resolved.pathname = `${root}${directory}`;
  } else {
    resolved.pathname = new URL(directory, base).pathname;
  }
  return resolved.host === 'github.com'
    ? resolved.href.replace(
        /(\/\/[^/]+\/[^/]+\/[^/]+)\/(?:blob|tree|edit)\//,
        '$1/tree/',
      )
    : resolved.href;
}

/** Where an entity's documentation source is, from its `techdocs-ref`. */
function docsLocation(entity: Entity): LocationRef | undefined {
  const docs = parseLocationRef(
    entity.metadata.annotations?.['backstage.io/techdocs-ref'],
  );
  if (docs?.type === 'url') {
    return docs;
  }
  const source = sourceLocation(entity);
  if (docs?.type !== 'dir' || !source) {
    return undefined;
  }
  if (source.type === 'url') {
    return {
      type: 'url',
      target: resolveSourceUrl(docs.target, source.target),
    };
  }
  const directory = source.target.slice(0, source.target.lastIndexOf('/'));
  const target =
    source.type === 'file' ? childPath(directory, docs.target) : undefined;
  return target === undefined ? undefined : { type: 'dir', target };
}

techdocsRoutes.get('/metadata/entity/:namespace/:kind/:name', async c => {
  const { namespace, kind, name } = c.req.param();
  const stored = await entityByName(c.env.DB, kind, namespace, name);
  const entity = stored === null ? undefined : (JSON.parse(stored) as Entity);
  const locationMetadata = entity && docsLocation(entity);
  if (!locationMetadata) {
    throw notFoundError(
      `Unable to get metadata for '${entityRef({ namespace, kind, name })}'`,
    );
  }
  return c.json({ ...entity, locationMetadata });
});

// Documentation is built by the pipeline, never on request, so what is
// published is always as up to date as it gets. The front end waits for
// this event before it shows a page.
techdocsRoutes.get('/sync/:namespace/:kind/:name', async c => {
  const { namespace, kind, name } = c.req.param();
  if ((await entityByName(c.env.DB, kind, namespace, name)) === null) {
    throw notFoundError('Entity metadata UID missing');
  }
  return new Response('event: finish\ndata: {"updated":false}\n\n', {
    headers: {
      'content-type': 'text/event-stream',
      'cache-control': 'no-cache',
    },
  });
});
