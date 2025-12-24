/**
 * =============================================================================
 * Branding Settings Backend Plugin
 * =============================================================================
 *
 * Provides a REST API for storing and retrieving custom branding settings:
 * - Organization/Team name
 * - Custom logo (full and icon versions)
 *
 * Logo files are stored in MinIO (S3-compatible storage).
 * Settings metadata are stored in PostgreSQL.
 *
 * Endpoints:
 * - GET    /api/branding-settings              - Get current branding settings
 * - POST   /api/branding-settings              - Update branding settings (admin only)
 * - POST   /api/branding-settings/logo/upload  - Upload logo files (admin only)
 * - DELETE /api/branding-settings/logo         - Reset logo to default (admin only)
 * - DELETE /api/branding-settings              - Reset all branding to default (admin only)
 * - GET    /api/branding-settings/admin-check  - Check if current user is admin
 *
 * MinIO Bucket: backstage-assets
 * Logo paths:
 * - logos/logo-full.{ext}   - Full sidebar logo
 * - logos/logo-icon.{ext}   - Collapsed sidebar icon
 *
 * =============================================================================
 */

import {
  createBackendPlugin,
  coreServices,
} from '@backstage/backend-plugin-api';
import { initializeTables } from './database';
import { createS3Client } from './storage';
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
        config: coreServices.rootConfig,
        httpAuth: coreServices.httpAuth,
        userInfo: coreServices.userInfo,
      },
      async init({ httpRouter, logger, database, config, httpAuth, userInfo }) {
        logger.info('Initializing branding-settings plugin');

        // Get database client for branding settings storage
        const knex = await database.getClient();

        // Initialize database tables
        await initializeTables(knex, logger);

        // Get MinIO configuration
        const minioEndpoint =
          config.getOptionalString('brandingSettings.minio.endpoint') ||
          process.env.MINIO_ENDPOINT ||
          'http://minio:9000';
        const minioAccessKey =
          config.getOptionalString('brandingSettings.minio.accessKeyId') ||
          process.env.MINIO_ACCESS_KEY;
        const minioSecretKey =
          config.getOptionalString('brandingSettings.minio.secretAccessKey') ||
          process.env.MINIO_SECRET_KEY;
        const minioBucket =
          config.getOptionalString('brandingSettings.minio.bucket') ||
          process.env.BRANDING_BUCKET ||
          'backstage-assets';

        if (!minioAccessKey || !minioSecretKey) {
          logger.warn(
            'MinIO credentials not configured - logo upload will fail. Set MINIO_ACCESS_KEY and MINIO_SECRET_KEY environment variables.',
          );
        }

        // Create S3 client for MinIO
        const s3Client = createS3Client(
          minioEndpoint,
          minioAccessKey || '',
          minioSecretKey || '',
        );

        logger.info(
          `Branding settings using MinIO at ${minioEndpoint}, bucket: ${minioBucket}`,
        );

        // Create and register the router
        const router = createRouter({
          knex,
          logger,
          s3Client,
          bucket: minioBucket,
          httpAuth,
          userInfo,
        });

        httpRouter.use(router);
        httpRouter.addAuthPolicy({
          path: '/',
          allow: 'unauthenticated',
        });
      },
    });
  },
});

export default brandingSettingsPlugin;
