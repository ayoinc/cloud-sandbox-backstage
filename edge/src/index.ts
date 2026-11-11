import { Hono } from 'hono';
import { guestRoutes, requireUser } from './auth';
import { organisationRoutes, publicOrganisationRoutes } from './organisations';
import { portalAdminRoutes } from './portalAdmins';
import { catalogRoutes } from './catalog/routes';
import { handleError, notImplementedError } from './errors';
import { GITHUB_API_PATH, githubRoutes } from './github';
import { configuredProviders, oauthRoutes } from './oauth';
import { ownershipRoutes } from './ownership';
import { pipelineRoutes } from './pipeline';
import {
  notificationRoutes,
  permissionRoutes,
  userSettingsRoutes,
  signalRoutes,
} from './portal';
import { scaffolderRoutes } from './scaffolder';
import { searchRoutes } from './search';
import { techdocsRoutes } from './techdocs';
import type { AppEnv } from './types';

/**
 * Cloud Sandbox on Cloudflare Workers.
 *
 * Serves the built Backstage front end from static assets and answers the
 * Backstage REST calls it makes from D1 and R2. The Backstage backend does
 * not run here: GitHub Actions pipelines run it to process the catalog,
 * build TechDocs and execute software templates, and push the results to
 * `/api/pipeline`.
 */
// A slash at the end of an address makes no difference, as on the Node
// backend.
const app = new Hono<AppEnv>({ strict: false });

app.onError(handleError);

// Public: needed before sign-in.
app.route('/api/auth/guest', guestRoutes);
app.route('/api/auth', oauthRoutes);
app.route('/api/organisations', publicOrganisationRoutes);

// These check their callers themselves: the pipeline has its own token,
// the GitHub client sends the user token under another scheme, and docs
// files also accept a cookie.
app.route('/api/pipeline', pipelineRoutes);
app.route(GITHUB_API_PATH, githubRoutes);
app.route('/api/techdocs', techdocsRoutes);

// A WebSocket: its token arrives as the subprotocol, not in a header.
app.route('/api/signals', signalRoutes);

app.use('/api/*', requireUser);
app.route('/api/catalog', catalogRoutes);
app.route('/api/permission', permissionRoutes);
app.route('/api/user-settings', userSettingsRoutes);
app.route('/api/branding-settings', portalAdminRoutes);
app.route('/api/organisations', organisationRoutes);
app.route('/api/ownership-management', ownershipRoutes);
app.route('/api/notifications', notificationRoutes);
app.route('/api/search', searchRoutes);
app.route('/api/scaffolder', scaffolderRoutes);

app.all('/api/*', c => {
  throw notImplementedError(
    `${c.req.method} ${c.req.path} is not available on the Cloudflare edge deployment`,
  );
});

interface AppConfig {
  context: string;
  data: Record<string, unknown>;
}

// Everything else is the front end. The app was built without knowing where
// it would run, so each page gets a config layer naming this origin as app
// and backend, and the sign-in methods this Worker has configured.
app.all('*', async c => {
  // A page is rewritten below, from settings the stored file knows nothing
  // of. Asking the store whether its copy has changed would answer for the
  // file, not for the page, so pages are always fetched whole.
  const request = new Request(c.req.raw);
  if (c.req.header('accept')?.includes('text/html')) {
    request.headers.delete('if-none-match');
    request.headers.delete('if-modified-since');
  }
  const response = await c.env.ASSETS.fetch(request);
  if (!response.headers.get('content-type')?.includes('text/html')) {
    return response;
  }
  const { origin } = new URL(c.req.url);
  const signIn = [
    ...configuredProviders(c.env),
    ...(c.env.GUEST_AUTH_ENABLED === 'true' ? ['guest'] : []),
  ];
  let json = '';
  // The site token of Cloudflare Web Analytics, which counts visits without
  // cookies. Anything that is not one is ignored: it goes into the page.
  const analytics = /^[0-9a-f]{32}$/.exec(
    c.env.WEB_ANALYTICS_TOKEN?.trim() ?? '',
  )?.[0];
  const page = new HTMLRewriter()
    // The public pages say whether visits are counted, in two variants:
    // show the one that is true here.
    .on('[data-portal-analytics]', {
      element(element) {
        if (analytics) {
          element.removeAttribute('hidden');
        }
      },
    })
    .on('[data-portal-no-analytics]', {
      element(element) {
        if (analytics) {
          element.setAttribute('hidden', '');
        }
      },
    })
    .on('body', {
      element(element) {
        if (analytics) {
          element.append(
            // As the dashboard writes it (Web Analytics > Manage site).
            `<script type="module" src="https://static.cloudflareinsights.com/beacon.min.js" data-cf-beacon='{"token": "${analytics}"}'></script>`,
            { html: true },
          );
        }
      },
    })
    .on('script[type="backstage.io/config"]', {
      text(chunk) {
        json += chunk.text;
        if (!chunk.lastInTextNode) {
          chunk.remove();
          return;
        }
        const configs = JSON.parse(json) as AppConfig[];
        // Layers merge, so the built-in sign-in list and integrations have
        // to be removed for this deployment's to replace them.
        for (const config of configs) {
          delete config.data.auth;
          delete config.data.integrations;
        }
        configs.push({
          context: 'cloudflare-edge',
          data: {
            app: { baseUrl: origin },
            backend: { baseUrl: origin },
            // Pages about the GitHub organisation link to the one this
            // portal is deployed from.
            organization: { githubOrg: c.env.PORTAL_REPO.split('/')[0] },
            auth: {
              providers: Object.fromEntries(signIn.map(id => [id, {}])),
            },
            // GitHub API calls from the browser go through this Worker,
            // which holds the only GitHub token.
            integrations: {
              github: [
                {
                  host: 'github.com',
                  apiBaseUrl: `${origin}${GITHUB_API_PATH}`,
                },
              ],
            },
            // Task logs are read by polling: a Worker cannot hold an event
            // stream open for as long as a template runs.
            scaffolder: { useLongPollingLogs: true },
          },
        });
        // Later layers override earlier ones. `<` is escaped so the JSON
        // cannot close the script element.
        chunk.replace(JSON.stringify(configs).replaceAll('<', '\\u003c'), {
          html: true,
        });
      },
    })
    .transform(response);
  // An internal portal: keep its pages out of search engines. And the
  // file's validators are not the page's: see above.
  const headers = new Headers(page.headers);
  headers.set('x-robots-tag', 'noindex');
  headers.delete('etag');
  headers.delete('last-modified');
  return new Response(page.body, { status: page.status, headers });
});

export default app;
