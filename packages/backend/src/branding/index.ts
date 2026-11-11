/**
 * =============================================================================
 * Branding Settings Backend Plugin
 * =============================================================================
 *
 * Provides a REST API for storing and retrieving custom branding settings:
 * - Organization/Team name
 * - Custom logo (full and icon versions)
 *
 * Settings and logo files are stored in the plugin's database.
 *
 * Endpoints:
 * - GET    /api/branding-settings              - Get current branding settings
 * - POST   /api/branding-settings              - Update branding settings (admin only)
 * - POST   /api/branding-settings/logo/upload  - Upload logo files (admin only)
 * - GET    /api/branding-settings/logo/:kind   - The full or icon logo (public)
 * - DELETE /api/branding-settings/logo         - Reset logo to default (admin only)
 * - DELETE /api/branding-settings              - Reset all branding to default (admin only)
 * - GET    /api/branding-settings/admin-check  - Check if current user is admin
 *
 * =============================================================================
 */

import {
  createBackendPlugin,
  coreServices,
} from '@backstage/backend-plugin-api';
import { initializeTables } from './database';
import { createRouter } from './routes';

export type { BrandingSettings } from './types';
export { DEFAULT_SETTINGS } from './types';
export { checkIsAdmin } from './database';

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

        // Get database client for branding settings storage
        const knex = await database.getClient();

        // Initialize database tables
        await initializeTables(knex, logger);

        // Create and register the router
        const router = createRouter({
          knex,
          logger,
          httpAuth,
          userInfo,
        });

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        httpRouter.use(router as any);
        httpRouter.addAuthPolicy({
          path: '/',
          allow: 'unauthenticated',
        });
      },
    });
  },
});

export default brandingSettingsPlugin;
