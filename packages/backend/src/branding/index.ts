/**
 * =============================================================================
 * Portal Admins Backend Plugin (plugin id `branding-settings`)
 * =============================================================================
 *
 * Holds the list of portal admins and its own management, and answers the
 * rest of the backend who is one (../accounts/directory.ts): the permission
 * policy and the ownership and clean-up plugins ask. The plugin id and
 * paths are the ones the front end uses for the list on every backend.
 *
 * Endpoints:
 * - GET    /api/branding-settings/admin-check  - Check if current user is admin
 * - GET    /api/branding-settings/admins       - List portal admins (admin only)
 * - POST   /api/branding-settings/admins       - Add a portal admin (admin only)
 * - DELETE /api/branding-settings/admins/:id   - Remove a portal admin (admin only)
 *
 * =============================================================================
 */

import {
  createBackendPlugin,
  coreServices,
} from '@backstage/backend-plugin-api';
import { provide } from '../accounts/directory';
import { checkIsAdmin, initializeTables, listPortalAdmins } from './database';
import { createRouter } from './routes';

export const brandingSettingsPlugin = createBackendPlugin({
  pluginId: 'branding-settings',
  register(env) {
    env.registerInit({
      deps: {
        httpRouter: coreServices.httpRouter,
        logger: coreServices.logger,
        database: coreServices.database,
        httpAuth: coreServices.httpAuth,
        userInfo: coreServices.userInfo,
      },
      async init({ httpRouter, logger, database, httpAuth, userInfo }) {
        logger.info('Initializing branding-settings plugin');

        // Get database client for the admin table
        const knex = await database.getClient();

        // Initialize database tables
        await initializeTables(knex, logger);

        provide({
          isPortalAdmin: (userRef, ownershipRefs) =>
            checkIsAdmin(knex, userRef, logger, ownershipRefs),
          portalAdmins: () => listPortalAdmins(knex),
        });

        // Create and register the router
        const router = createRouter({
          knex,
          logger,
          httpAuth,
          userInfo,
        });

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        httpRouter.use(router as any);
        // Every route checks for a signed-in user or an administrator
        // itself, and answers in its own format when there is none.
        httpRouter.addAuthPolicy({
          path: '/',
          allow: 'unauthenticated',
        });
      },
    });
  },
});

export default brandingSettingsPlugin;
