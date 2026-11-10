// What the pipeline scripts are told through the environment.
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseEnv } from 'node:util';

export const repoRoot = fileURLToPath(new URL('../../../', import.meta.url));

const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1', '[::1]']);

/**
 * The token of a Worker running locally with `yarn dev`, taken from
 * edge/.dev.vars so it never has to be typed or exported.
 */
function localWorkerToken(portalUrl) {
  if (!LOCAL_HOSTS.has(new URL(portalUrl).hostname)) {
    return undefined;
  }
  try {
    const vars = parseEnv(
      readFileSync(join(repoRoot, 'edge/.dev.vars'), 'utf8'),
    );
    return vars.PIPELINE_TOKEN || undefined;
  } catch (error) {
    if (error.code === 'ENOENT') {
      return undefined;
    }
    throw error;
  }
}

/**
 * Reads the settings and then removes the tokens from this process's
 * environment. The programs the scripts start (mkdocs, d2, git) run content
 * from other repositories and must not inherit them; the ones that need a
 * token, the pipeline backend and the portal Worker, are handed it explicitly.
 *
 * Which portal, one of:
 *
 *   PORTAL_URL             a portal that can be called directly: a Worker
 *                          running locally, e.g. http://localhost:8787
 *   PORTAL_PIPELINE_TOKEN  its PIPELINE_TOKEN (for a local Worker it is read
 *                          from edge/.dev.vars when not set)
 *
 *   CLOUDFLARE_API_TOKEN   the deployed portal, reached through Cloudflare's
 *                          API (see bridge.mjs). The token must be allowed to
 *                          edit D1, R2 and Workers scripts.
 *   CLOUDFLARE_ACCOUNT_ID  the account, when the token can see several
 *
 * And for both:
 *
 *   PORTAL_GITHUB_TOKEN    reads catalog files and documentation in private
 *                          repositories, creates repositories from templates
 *
 * In GitHub Actions the repository and branch come from GITHUB_SERVER_URL,
 * GITHUB_REPOSITORY and GITHUB_REF_NAME, and the run from GITHUB_RUN_ID.
 */
export function readSettings() {
  const env = process.env;
  const portalUrl = (env.PORTAL_URL ?? '').replace(/\/+$/, '');
  const cloudflareToken = env.CLOUDFLARE_API_TOKEN || undefined;
  if (!portalUrl && !cloudflareToken) {
    throw new Error(
      'Neither PORTAL_URL nor CLOUDFLARE_API_TOKEN is set. Set PORTAL_URL to a portal running locally, for example http://localhost:8787, or CLOUDFLARE_API_TOKEN to update the deployed portal.',
    );
  }
  const portalToken =
    portalUrl && (env.PORTAL_PIPELINE_TOKEN || localWorkerToken(portalUrl));
  if (portalUrl && !portalToken) {
    throw new Error(
      'PORTAL_PIPELINE_TOKEN is not set. It must equal the PIPELINE_TOKEN secret of the Worker at PORTAL_URL.',
    );
  }
  const githubToken = env.PORTAL_GITHUB_TOKEN || undefined;
  const accountId = env.CLOUDFLARE_ACCOUNT_ID || undefined;
  delete env.PORTAL_PIPELINE_TOKEN;
  delete env.PORTAL_GITHUB_TOKEN;
  delete env.CLOUDFLARE_API_TOKEN;

  const serverUrl = env.GITHUB_SERVER_URL || 'https://github.com';
  return {
    // PORTAL_URL wins: a developer pointing at a local Worker must never
    // write to the deployed one because a Cloudflare token is also set.
    portal: portalUrl ? { url: portalUrl, token: portalToken } : undefined,
    cloudflare: portalUrl
      ? undefined
      : { apiToken: cloudflareToken, accountId },
    githubToken,
    // Set when running in GitHub Actions: the repository these files are in.
    github:
      env.GITHUB_REPOSITORY && env.GITHUB_REF_NAME
        ? {
            serverUrl,
            repository: env.GITHUB_REPOSITORY,
            refName: env.GITHUB_REF_NAME,
          }
        : undefined,
    runUrl:
      env.GITHUB_REPOSITORY && env.GITHUB_RUN_ID
        ? `${serverUrl}/${env.GITHUB_REPOSITORY}/actions/runs/${env.GITHUB_RUN_ID}`
        : undefined,
  };
}

/**
 * Where a pipeline script keeps the pipeline backend's SQLite files and its
 * own working files: PIPELINE_DATA_DIR, or edge/.wrangler/<name>.
 */
export function dataDirFor(name) {
  return (
    process.env.PIPELINE_DATA_DIR || join(repoRoot, 'edge/.wrangler', name)
  );
}
