// Creates the portal's GitHub App through GitHub's app-manifest flow.
//
//   node scripts/create-github-app.mjs https://backstage.example.com
//
// Open the printed local URL in a browser signed in to GitHub and confirm.
// GitHub sends the new app's credentials back here; the client secret goes
// straight into the Worker (`wrangler secret put`) and into .dev.vars, and is
// never printed. The app's private key is not needed for sign-in and is
// discarded. Prints the client id to put in wrangler.jsonc.
import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { readFile, writeFile } from 'node:fs/promises';
import { createServer } from 'node:http';

const portalUrl = process.argv[2];
if (!portalUrl) {
  console.error('Usage: create-github-app.mjs <portal URL>');
  process.exit(1);
}
const PORT = 8911;
const local = `http://localhost:${PORT}`;
const state = randomUUID();

const manifest = {
  // GitHub allows 34 characters at most.
  name: `Cloud Sandbox ${new URL(portalUrl).hostname}`.slice(0, 34),
  url: portalUrl,
  description: 'Sign-in for the Cloud Sandbox developer portal.',
  redirect_url: `${local}/created`,
  callback_urls: [
    `${portalUrl}/api/auth/github/handler/frame`,
    'http://localhost:8787/api/auth/github/handler/frame',
  ],
  hook_attributes: { url: `${portalUrl}/api/github/webhook`, active: false },
  public: false,
  default_permissions: {},
  default_events: [],
};

const escapeHtml = value =>
  value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;');

function putSecret(name, value) {
  return new Promise((resolve, reject) => {
    const child = spawn('wrangler', ['secret', 'put', name], {
      stdio: ['pipe', 'ignore', 'inherit'],
    });
    child.on('error', reject);
    child.on('exit', code =>
      code === 0 ? resolve() : reject(new Error(`wrangler exited ${code}`)),
    );
    child.stdin.end(value);
  });
}

async function setDevVar(name, value) {
  const current = await readFile('.dev.vars', 'utf8').catch(() => '');
  const line = `${name}=${value}`;
  const pattern = new RegExp(`^${name}=.*$`, 'm');
  await writeFile(
    '.dev.vars',
    pattern.test(current)
      ? current.replace(pattern, line)
      : `${current.replace(/\n?$/, '\n')}${line}\n`,
    { mode: 0o600 },
  );
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url, local);
  if (url.pathname === '/') {
    response.setHeader('content-type', 'text/html; charset=utf-8');
    response.end(`<!doctype html><title>Create GitHub App</title>
<form id="create" action="https://github.com/settings/apps/new?state=${state}" method="post">
  <input type="hidden" name="manifest" value="${escapeHtml(
    JSON.stringify(manifest),
  )}">
  <button type="submit">Create the GitHub App</button>
</form>`);
    return;
  }
  if (url.pathname !== '/created') {
    response.statusCode = 404;
    response.end();
    return;
  }
  try {
    if (url.searchParams.get('state') !== state) {
      throw new Error('State does not match this run');
    }
    const conversion = await fetch(
      `https://api.github.com/app-manifests/${url.searchParams.get(
        'code',
      )}/conversions`,
      { method: 'POST', headers: { accept: 'application/vnd.github+json' } },
    );
    if (!conversion.ok) {
      throw new Error(`GitHub returned ${conversion.status}`);
    }
    const app = await conversion.json();
    await putSecret('GITHUB_CLIENT_SECRET', app.client_secret);
    await setDevVar('GITHUB_CLIENT_SECRET', app.client_secret);
    console.log(
      `CREATED ${JSON.stringify({
        slug: app.slug,
        owner: app.owner.login,
        clientId: app.client_id,
        settings: app.html_url,
      })}`,
    );
    response.end('GitHub App created. You can close this tab.');
    server.close();
  } catch (error) {
    console.log(`FAILED ${error.message}`);
    response.statusCode = 500;
    response.end(`Failed: ${error.message}`);
    server.close();
  }
});

server.listen(PORT, 'localhost', () => console.log(`OPEN ${local}/`));
