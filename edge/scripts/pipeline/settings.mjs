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
 * from other repositories and must not inherit them; the one that needs a
 * token, the pipeline backend, is handed it explicitly.
 *
 *   PORTAL_URL             where the portal runs, e.g. http://localhost:8787
 *   PORTAL_PIPELINE_TOKEN  the Worker's PIPELINE_TOKEN (for a local Worker it
 *                          is read from edge/.dev.vars when not set)
 *   PORTAL_GITHUB_TOKEN    reads catalog files and documentation in private
 *                          repositories, creates repositories from templates
 *
 * In GitHub Actions the repository and branch come from GITHUB_SERVER_URL,
 * GITHUB_REPOSITORY and GITHUB_REF_NAME, and the run from GITHUB_RUN_ID.
 */
export function readSettings() {
  const env = process.env;
  const portalUrl = (env.PORTAL_URL ?? '').replace(/\/+$/, '');
  if (!portalUrl) {
    throw new Error(
      'PORTAL_URL is not set. It is the address of the portal, for example http://localhost:8787.',
    );
  }
  const portalToken = env.PORTAL_PIPELINE_TOKEN || localWorkerToken(portalUrl);
  if (!portalToken) {
    throw new Error(
      'PORTAL_PIPELINE_TOKEN is not set. It must equal the PIPELINE_TOKEN secret of the Worker at PORTAL_URL.',
    );
  }
  const githubToken = env.PORTAL_GITHUB_TOKEN || undefined;
  delete env.PORTAL_PIPELINE_TOKEN;
  delete env.PORTAL_GITHUB_TOKEN;

  const serverUrl = env.GITHUB_SERVER_URL || 'https://github.com';
  return {
    portal: { url: portalUrl, token: portalToken },
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
