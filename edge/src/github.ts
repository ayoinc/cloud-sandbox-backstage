import { Hono } from 'hono';
import { callerRef, fromRegisteredFile, originOf, visibleTo } from './accounts';
import { isPortalAdmin } from './admin';
import { signInFromHeader } from './auth';
import { HttpError, notAllowedError, notFoundError } from './errors';
import type { AppEnv } from './types';

/**
 * Read-only GitHub Actions data for the CI tab.
 *
 * The front end's GitHub client is pointed here instead of api.github.com
 * and sends the user's portal token, the only credential the browser has.
 * Requests for the workflow runs of a repository in the catalog are passed
 * on to GitHub with the Worker's own token, for callers who may see an
 * entity of that repository. Nothing else is.
 *
 * An entity names its repository itself, in an annotation. For one that
 * comes from a file registered through the portal that is taken only when
 * it names the repository the file is in: anyone can register a file, and
 * would otherwise read the runs of any repository the token reads by naming
 * it. The repository the portal itself runs in, which the pipeline writes
 * on every component and template the operator keeps there, holds the logs
 * of everyone's template runs: it is read by portal administrators only.
 */
export const githubRoutes = new Hono<AppEnv>();

/** Where the routes are mounted, and so the GitHub API address given to the front end. */
export const GITHUB_API_PATH = '/api/github';

const GITHUB_API = 'https://api.github.com';
const USER_AGENT = 'cloud-sandbox-portal';

/** What may be read of a repository: paths after `/repos/<owner>/<repo>`. */
const READABLE = [
  // The repository and its branches. The runs table asks for the default
  // branch and fills its branch filter before it lists any run.
  /^(\/branches)?$/,
  /^\/actions\/runs(\/\d+(\/attempts\/\d+)?(\/(jobs|logs))?)?$/,
  /^\/actions\/jobs\/\d+(\/logs)?$/,
  /^\/actions\/workflows(\/[\w.-]+(\/runs)?)?$/,
];

// The GitHub client sends `token <t>`, or `bearer <t>` for a token that
// looks like a JWT, as the portal's do.
githubRoutes.use('*', async (c, next) => {
  await signInFromHeader(c, ['bearer', 'token']);
  await next();
});

githubRoutes.all('*', async c => {
  if (c.req.method !== 'GET') {
    throw notAllowedError('GitHub can only be read through the portal');
  }
  const url = new URL(c.req.url);
  const [, owner, repo, rest = ''] =
    /^\/repos\/([\w.-]+)\/([\w.-]+)(\/.*)?$/.exec(
      url.pathname.slice(GITHUB_API_PATH.length),
    ) ?? [];
  if (!owner || !READABLE.some(pattern => pattern.test(rest))) {
    throw notFoundError(
      'Only the GitHub Actions runs of a repository can be read through the portal',
    );
  }
  const slug = `${owner}/${repo}`.toLowerCase();
  const missing = notFoundError(
    `No entity in the catalog belongs to ${owner}/${repo}`,
  );
  if (slug === c.env.PORTAL_REPO.toLowerCase() && !(await isPortalAdmin(c))) {
    throw missing;
  }
  // Catalog search values are stored in lower case. A repository whose
  // entities the caller may not see is, to them, not in the catalog.
  const visible = visibleTo(callerRef(c));
  const ownFile = `url:https://github.com/${slug}/`;
  const inCatalog = await c.env.DB.prepare(
    `SELECT 1 FROM search s JOIN final_entities e ON e.entity_id = s.entity_id WHERE s.key = 'metadata.annotations.github.com/project-slug' AND s.value = ? AND (${
      visible.sql
    }) AND (substr(${originOf(
      'e',
    )}, 1, length(?)) = ? OR NOT ${fromRegisteredFile('e')}) LIMIT 1`,
  )
    .bind(slug, ...visible.params, ownFile, ownFile)
    .first();
  if (!inCatalog) {
    throw missing;
  }
  if (!c.env.PORTAL_GITHUB_TOKEN) {
    throw new HttpError(
      503,
      'ServiceUnavailableError',
      'GitHub Actions data is not available: the PORTAL_GITHUB_TOKEN secret is not set',
    );
  }
  let response = await fetch(
    `${GITHUB_API}/repos/${owner}/${repo}${rest}${url.search}`,
    {
      headers: {
        accept: c.req.header('accept') ?? 'application/vnd.github+json',
        authorization: `Bearer ${c.env.PORTAL_GITHUB_TOKEN}`,
        'user-agent': USER_AGENT,
      },
      redirect: 'manual',
    },
  );
  // Logs are answered with a redirect to a signed address on another host.
  // It is followed here, by hand, so the token is never sent to that host
  // and the browser is not sent to an address outside the portal.
  const location = response.headers.get('location');
  if (response.status >= 300 && response.status < 400 && location) {
    response = await fetch(location, { headers: { 'user-agent': USER_AGENT } });
  }
  const headers = new Headers({ 'cache-control': 'no-store' });
  for (const name of ['content-type', 'link']) {
    const value = response.headers.get(name);
    if (value) {
      headers.set(name, value);
    }
  }
  return new Response(response.body, { status: response.status, headers });
});
