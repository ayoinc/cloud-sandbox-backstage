import {
  ApiBlueprint,
  configApiRef,
  createFrontendModule,
  discoveryApiRef,
  fetchApiRef,
  identityApiRef,
} from '@backstage/frontend-plugin-api';
import { scmIntegrationsApiRef } from '@backstage/integration-react';
import { catalogEntityCreatePermission } from '@backstage/plugin-catalog-common/alpha';
import catalogImportPlugin from '@backstage/plugin-catalog-import/alpha';
import scaffolderPlugin from '@backstage/plugin-scaffolder/alpha';
import { ScaffolderClient } from '@backstage/plugin-scaffolder-common';
import { taskCreatePermission } from '@backstage/plugin-scaffolder-common/alpha';
import { scaffolderApiRef } from '@backstage/plugin-scaffolder-react';

/** Registering entities requires the catalog entity create permission. */
export const catalogImportModule = createFrontendModule({
  pluginId: 'catalog-import',
  extensions: [
    catalogImportPlugin.getExtension('page:catalog-import').override({
      if: { permissions: { $contains: catalogEntityCreatePermission.name } },
    }),
  ],
});

/**
 * The scaffolder client, reading task logs by polling when
 * `scaffolder.useLongPollingLogs` is set. Deployments that cannot hold a
 * streaming connection open (the Cloudflare Worker) set it; others keep the
 * default event stream.
 */
const scaffolderApi = ApiBlueprint.make({
  params: defineParams =>
    defineParams({
      api: scaffolderApiRef,
      deps: {
        configApi: configApiRef,
        discoveryApi: discoveryApiRef,
        scmIntegrationsApi: scmIntegrationsApiRef,
        fetchApi: fetchApiRef,
        identityApi: identityApiRef,
      },
      factory: ({ configApi, ...apis }) =>
        new ScaffolderClient({
          ...apis,
          useLongPollingLogs: configApi.getOptionalBoolean(
            'scaffolder.useLongPollingLogs',
          ),
        }),
    }),
});

/** Running software templates requires the scaffolder task create permission. */
export const scaffolderModule = createFrontendModule({
  pluginId: 'scaffolder',
  extensions: [
    scaffolderPlugin.getExtension('page:scaffolder').override({
      if: { permissions: { $contains: taskCreatePermission.name } },
    }),
    scaffolderApi,
  ],
});
