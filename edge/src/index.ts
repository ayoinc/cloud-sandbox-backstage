import { Hono } from 'hono';
import { guestRoutes, requireUser } from './auth';
import { brandingRoutes, publicBrandingRoutes } from './branding';
import { catalogRoutes } from './catalog/routes';
import { handleError, notImplementedError } from './errors';
import { GITHUB_API_PATH, githubRoutes } from './github';
import { isRecord } from './json';
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
const app = new Hono<AppEnv>();

app.onError(handleError);

// Public: needed before sign-in.
app.route('/api/auth/guest', guestRoutes);
app.route('/api/auth', oauthRoutes);
app.route('/api/branding-settings', publicBrandingRoutes);

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
app.route('/api/branding-settings', brandingRoutes);
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
  const response = await c.env.ASSETS.fetch(c.req.raw);
  if (!response.headers.get('content-type')?.includes('text/html')) {
    return response;
  }
  const { origin } = new URL(c.req.url);
  const signIn = [
    ...configuredProviders(c.env),
    ...(c.env.GUEST_AUTH_ENABLED === 'true' ? ['guest'] : []),
  ];
  let json = '';
  const contact = c.env.PORTAL_CONTACT_EMAIL?.trim();
  const page = new HTMLRewriter()
    // The privacy notice names who runs the portal, which the built page
    // cannot know. Text set here is escaped by the rewriter.
    .on('[data-portal-host]', {
      element(element) {
        element.setInnerContent(new URL(c.req.url).host);
      },
    })
    .on('[data-portal-contact]', {
      element(element) {
        if (contact) {
          element.setInnerContent(contact);
          element.setAttribute('href', `mailto:${contact}`);
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
        // A list replaces the built-in one, so carry the built-in entries.
        const builtInExtensions = configs.flatMap(config => {
          const { app } = config.data;
          return isRecord(app) && Array.isArray(app.extensions)
            ? (app.extensions as unknown[])
            : [];
        });
        configs.push({
          context: 'cloudflare-edge',
          data: {
            app: {
              baseUrl: origin,
              // The template editor tries a template out on the backend,
              // and templates only run in GitHub Actions here.
              extensions: [
                ...builtInExtensions,
                { 'sub-page:scaffolder/editor': false },
              ],
            },
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
  // An internal portal: keep its pages out of search engines.
  const headers = new Headers(page.headers);
  headers.set('x-robots-tag', 'noindex');
  return new Response(page.body, { status: page.status, headers });
});

export default app;
