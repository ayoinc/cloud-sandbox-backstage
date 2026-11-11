import { ConfigReader } from '@backstage/config';
import { defaultConfigLoader } from '@backstage/core-app-api';
import { createApp } from '@backstage/frontend-defaults';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import { activityModule } from './modules/activity';
import { adminModule, settingsModule } from './modules/admin';
import { authModule } from './modules/auth';
import { brandModule, brandTechDocsModule } from './modules/brand';
import { catalogModule } from './modules/catalog';
import { homeModule } from './modules/home';
import { navModule } from './modules/nav';
import { catalogImportModule, scaffolderModule } from './modules/permissions';
import { sessionModule } from './modules/session';
import {
  loadBrandIdentity,
  organisationPath,
  organisationSlug,
} from '@internal/brand';

/**
 * The built-in config, with the app's address ending at the organisation
 * this page is under: at /o/acme/catalog the app lives at /o/acme, so every
 * route and link stays inside it, and the organisation's name and look are
 * loaded before anything is drawn. As the built-in loader does, an address
 * configured for this host is read against where the page was really
 * loaded from.
 */
async function loadConfig() {
  const configs = await defaultConfigLoader();
  const configured = ConfigReader.fromConfigs(configs);
  const app = new URL(configured.getString('app.baseUrl'));
  const backend = new URL(configured.getString('backend.baseUrl'));
  const sameOrigin = app.origin === backend.origin;
  const { protocol, host, origin } = window.location;
  const backendUrl = (
    sameOrigin ? `${protocol}//${host}${backend.pathname}` : backend.href
  ).replace(/\/$/, '');
  const { name } = await loadBrandIdentity(backendUrl);
  if (name) {
    // Pages that set a title of their own add the app's, set below.
    document.title = name;
  }
  return {
    config: ConfigReader.fromConfigs([
      ...configs,
      {
        context: 'organisation-address',
        data: {
          app: {
            baseUrl: (
              origin + organisationPath(organisationSlug(), app.pathname)
            ).replace(/\/$/, ''),
            // The browser tab names the organisation,
            ...(name && { title: name }),
          },
          backend: { baseUrl: backendUrl },
          // and so does the catalog's heading.
          ...(name && { organization: { name } }),
        },
      },
    ]),
  };
}

export default createApp({
  advanced: { configLoader: loadConfig },
  features: [
    catalogPlugin,
    brandModule,
    brandTechDocsModule,
    navModule,
    homeModule,
    authModule,
    sessionModule,
    activityModule,
    adminModule,
    settingsModule,
    catalogModule,
    catalogImportModule,
    scaffolderModule,
  ],
});
