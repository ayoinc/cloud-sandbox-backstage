import {
  createBackendPlugin,
  coreServices,
} from '@backstage/backend-plugin-api';
import { Router } from 'express';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import multer from 'multer';

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

interface BrandingSettings {
  organizationName: string | null;
  logoFullUrl: string | null;
  logoIconUrl: string | null;
  primaryColor: string | null;
  updatedAt: string;
  updatedBy: string | null;
}

const DEFAULT_SETTINGS: BrandingSettings = {
  organizationName: null,
  logoFullUrl: null,
  logoIconUrl: null,
  primaryColor: null,
  updatedAt: new Date().toISOString(),
  updatedBy: null,
};

// Multer configuration for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB max file size
  },
  fileFilter: (_req, file, cb) => {
    // Accept images only
    const allowedMimes = ['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp', 'image/gif'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only PNG, JPEG, SVG, WebP, and GIF are allowed.'));
    }
  },
});

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

        // Get database client
        const knex = await database.getClient();

        // Create table if not exists
        const hasTable = await knex.schema.hasTable('branding_settings');
        if (!hasTable) {
          logger.info('Creating branding_settings table');
          await knex.schema.createTable('branding_settings', (table) => {
            table.string('id').primary().defaultTo('default');
            table.string('organization_name').nullable();
            table.text('logo_full_url').nullable();
            table.text('logo_icon_url').nullable();
            table.string('primary_color').nullable();
            table.timestamp('updated_at').defaultTo(knex.fn.now());
            table.string('updated_by').nullable();
          });
          // Insert default row
          await knex('branding_settings').insert({
            id: 'default',
            organization_name: null,
            logo_full_url: null,
            logo_icon_url: null,
            primary_color: null,
            updated_at: new Date().toISOString(),
            updated_by: null,
          });
        }

        // Initialize S3 client for MinIO
        const minioEndpoint = config.getOptionalString('brandingSettings.minio.endpoint') 
          || process.env.MINIO_ENDPOINT 
          || 'http://minio:9000';
        const minioAccessKey = config.getOptionalString('brandingSettings.minio.accessKeyId')
          || process.env.MINIO_ACCESS_KEY 
          || 'backstage';
        const minioSecretKey = config.getOptionalString('brandingSettings.minio.secretAccessKey')
          || process.env.MINIO_SECRET_KEY 
          || 'backstage123';
        const minioBucket = config.getOptionalString('brandingSettings.minio.bucket')
          || process.env.BRANDING_BUCKET
          || 'backstage-assets';
        const minioPublicUrl = config.getOptionalString('brandingSettings.minio.publicUrl')
          || process.env.MINIO_PUBLIC_URL
          || 'http://localhost:9000';

        const s3Client = new S3Client({
          endpoint: minioEndpoint,
          region: 'us-east-1',
          credentials: {
            accessKeyId: minioAccessKey,
            secretAccessKey: minioSecretKey,
          },
          forcePathStyle: true, // Required for MinIO
        });

        logger.info(`Branding settings using MinIO at ${minioEndpoint}, bucket: ${minioBucket}`);

        const router = Router();

        // Helper function to get current settings from database
        async function getCurrentSettings(): Promise<BrandingSettings> {
          const row = await knex('branding_settings')
            .where('id', 'default')
            .first();

          if (!row) {
            return DEFAULT_SETTINGS;
          }

          return {
            organizationName: row.organization_name,
            logoFullUrl: row.logo_full_url,
            logoIconUrl: row.logo_icon_url,
            primaryColor: row.primary_color,
            updatedAt: row.updated_at,
            updatedBy: row.updated_by,
          };
        }

        // Helper to check admin and get user ref
        async function requireAdmin(req: any, res: any): Promise<string | null> {
          try {
            const credentials = await httpAuth.credentials(req, {
              allow: ['user'],
            });

            const user = await userInfo.getUserInfo(credentials);
            const userEntityRef = user.userEntityRef;

            if (!userEntityRef) {
              res.status(401).json({ error: 'Authentication required' });
              return null;
            }

            const isAdmin = await checkIsAdmin(knex, userEntityRef, logger);
            
            if (!isAdmin) {
              logger.warn(`Non-admin user ${userEntityRef} attempted admin action`);
              res.status(403).json({ error: 'Admin access required' });
              return null;
            }

            return userEntityRef;
          } catch (error) {
            res.status(401).json({ error: 'Authentication required' });
            return null;
          }
        }

        // =======================================================================
        // GET /api/branding-settings - Get current branding settings (public)
        // =======================================================================
        router.get('/', async (_req, res) => {
          try {
            const settings = await getCurrentSettings();
            return res.json(settings);
          } catch (error) {
            logger.error('Failed to get branding settings', error as Error);
            return res.status(500).json({ error: 'Failed to get branding settings' });
          }
        });

        // =======================================================================
        // POST /api/branding-settings - Update branding settings (admin only)
        // =======================================================================
        router.post('/', async (req, res) => {
          const userEntityRef = await requireAdmin(req, res);
          if (!userEntityRef) return;

          try {
            const { organizationName, primaryColor, logoFullUrl, logoIconUrl } = req.body;

            const updates: any = {
              updated_at: new Date().toISOString(),
              updated_by: userEntityRef,
            };

            // Only update fields that are explicitly provided
            if (organizationName !== undefined) {
              updates.organization_name = organizationName || null;
            }
            if (primaryColor !== undefined) {
              updates.primary_color = primaryColor || null;
            }
            if (logoFullUrl !== undefined) {
              updates.logo_full_url = logoFullUrl || null;
            }
            if (logoIconUrl !== undefined) {
              updates.logo_icon_url = logoIconUrl || null;
            }

            await knex('branding_settings')
              .where('id', 'default')
              .update(updates);

            logger.info(`Branding settings updated by ${userEntityRef}`);

            const newSettings = await getCurrentSettings();
            return res.json(newSettings);
          } catch (error) {
            logger.error('Failed to update branding settings', error as Error);
            return res.status(500).json({ error: 'Failed to update branding settings' });
          }
        });

        // =======================================================================
        // POST /api/branding-settings/logo/upload - Upload logo files (admin only)
        // =======================================================================
        const uploadMiddleware = upload.fields([
          { name: 'logoFull', maxCount: 1 },
          { name: 'logoIcon', maxCount: 1 },
        ]);
        router.post('/logo/upload', (req, res, next) => {
          uploadMiddleware(req as any, res as any, next);
        }, async (req, res) => {
            const userEntityRef = await requireAdmin(req, res);
            if (!userEntityRef) return;

            try {
              const files = req.files as { [fieldname: string]: Express.Multer.File[] };
              const currentSettings = await getCurrentSettings();
              
              let logoFullUrl = currentSettings.logoFullUrl;
              let logoIconUrl = currentSettings.logoIconUrl;

              // Upload logoFull if provided
              if (files.logoFull && files.logoFull[0]) {
                const file = files.logoFull[0];
                const ext = getExtension(file.mimetype);
                const key = `logos/logo-full.${ext}`;

                await s3Client.send(new PutObjectCommand({
                  Bucket: minioBucket,
                  Key: key,
                  Body: file.buffer,
                  ContentType: file.mimetype,
                  CacheControl: 'max-age=31536000', // 1 year cache
                }));

                logoFullUrl = `${minioPublicUrl}/${minioBucket}/${key}?t=${Date.now()}`;
                logger.info(`Uploaded logo-full to ${key}`);
              }

              // Upload logoIcon if provided
              if (files.logoIcon && files.logoIcon[0]) {
                const file = files.logoIcon[0];
                const ext = getExtension(file.mimetype);
                const key = `logos/logo-icon.${ext}`;

                await s3Client.send(new PutObjectCommand({
                  Bucket: minioBucket,
                  Key: key,
                  Body: file.buffer,
                  ContentType: file.mimetype,
                  CacheControl: 'max-age=31536000',
                }));

                logoIconUrl = `${minioPublicUrl}/${minioBucket}/${key}?t=${Date.now()}`;
                logger.info(`Uploaded logo-icon to ${key}`);
              }

              // Update database
              await knex('branding_settings')
                .where('id', 'default')
                .update({
                  logo_full_url: logoFullUrl,
                  logo_icon_url: logoIconUrl,
                  updated_at: new Date().toISOString(),
                  updated_by: userEntityRef,
                });

              logger.info(`Logo uploaded by ${userEntityRef}`);

              const newSettings = await getCurrentSettings();
              return res.json(newSettings);
            } catch (error) {
              logger.error('Failed to upload logo', error as Error);
              return res.status(500).json({ error: 'Failed to upload logo' });
            }
        });

        // =======================================================================
        // DELETE /api/branding-settings/logo - Reset logo to default (admin only)
        // =======================================================================
        router.delete('/logo', async (req, res) => {
          const userEntityRef = await requireAdmin(req, res);
          if (!userEntityRef) return;

          try {
            // Try to delete files from MinIO (ignore errors if files don't exist)
            const extensions = ['png', 'svg', 'jpg', 'webp', 'gif'];
            for (const ext of extensions) {
              try {
                await s3Client.send(new DeleteObjectCommand({
                  Bucket: minioBucket,
                  Key: `logos/logo-full.${ext}`,
                }));
              } catch (e) { /* ignore */ }
              
              try {
                await s3Client.send(new DeleteObjectCommand({
                  Bucket: minioBucket,
                  Key: `logos/logo-icon.${ext}`,
                }));
              } catch (e) { /* ignore */ }
            }

            // Reset logo URLs in database
            await knex('branding_settings')
              .where('id', 'default')
              .update({
                logo_full_url: null,
                logo_icon_url: null,
                updated_at: new Date().toISOString(),
                updated_by: userEntityRef,
              });

            logger.info(`Logo reset by ${userEntityRef}`);

            const newSettings = await getCurrentSettings();
            return res.json(newSettings);
          } catch (error) {
            logger.error('Failed to reset logo', error as Error);
            return res.status(500).json({ error: 'Failed to reset logo' });
          }
        });

        // =======================================================================
        // DELETE /api/branding-settings - Reset all branding to default (admin only)
        // =======================================================================
        router.delete('/', async (req, res) => {
          const userEntityRef = await requireAdmin(req, res);
          if (!userEntityRef) return;

          try {
            // Delete logo files from MinIO
            const extensions = ['png', 'svg', 'jpg', 'webp', 'gif'];
            for (const ext of extensions) {
              try {
                await s3Client.send(new DeleteObjectCommand({
                  Bucket: minioBucket,
                  Key: `logos/logo-full.${ext}`,
                }));
              } catch (e) { /* ignore */ }
              
              try {
                await s3Client.send(new DeleteObjectCommand({
                  Bucket: minioBucket,
                  Key: `logos/logo-icon.${ext}`,
                }));
              } catch (e) { /* ignore */ }
            }

            // Reset all branding settings in database
            await knex('branding_settings')
              .where('id', 'default')
              .update({
                organization_name: null,
                logo_full_url: null,
                logo_icon_url: null,
                primary_color: null,
                updated_at: new Date().toISOString(),
                updated_by: userEntityRef,
              });

            logger.info(`All branding settings reset by ${userEntityRef}`);

            return res.json(DEFAULT_SETTINGS);
          } catch (error) {
            logger.error('Failed to reset branding settings', error as Error);
            return res.status(500).json({ error: 'Failed to reset branding settings' });
          }
        });

        // =======================================================================
        // GET /api/branding-settings/admin-check - Check if current user is admin
        // =======================================================================
        router.get('/admin-check', async (req, res) => {
          try {
            const credentials = await httpAuth.credentials(req, {
              allow: ['user'],
            });

            const user = await userInfo.getUserInfo(credentials);
            const userEntityRef = user.userEntityRef;

            if (!userEntityRef) {
              return res.json({ isAdmin: false });
            }

            const isAdmin = await checkIsAdmin(knex, userEntityRef, logger);
            return res.json({ isAdmin, userEntityRef });
          } catch (error) {
            return res.json({ isAdmin: false });
          }
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

/**
 * Get file extension from MIME type
 */
function getExtension(mimeType: string): string {
  const mimeToExt: Record<string, string> = {
    'image/png': 'png',
    'image/jpeg': 'jpg',
    'image/svg+xml': 'svg',
    'image/webp': 'webp',
    'image/gif': 'gif',
  };
  return mimeToExt[mimeType] || 'png';
}

/**
 * Check if user is an admin by looking up their group membership in the catalog.
 * Admins are members of the 'admins' group.
 */
async function checkIsAdmin(
  knex: any,
  userEntityRef: string,
  logger: any,
): Promise<boolean> {
  try {
    // Parse user entity ref (format: user:default/username)
    const match = userEntityRef.match(/^user:([^/]+)\/(.+)$/);
    if (!match) {
      return false;
    }

    const [, _namespace, username] = match;

    // Check the catalog for user's group membership
    // Query the relations table to find if user is member of admins group
    const hasRelationsTable = await knex.schema.hasTable('relations');
    
    if (hasRelationsTable) {
      // Check if user has memberOf relation to admins group
      const relation = await knex('relations')
        .where('originating_entity_id', userEntityRef)
        .andWhere('type', 'memberOf')
        .andWhere('target_entity_ref', 'group:default/admins')
        .first();

      if (relation) {
        logger.debug(`User ${userEntityRef} is admin via relations table`);
        return true;
      }
    }

    // Alternative: Check the final_entities table for user spec
    const hasFinalEntitiesTable = await knex.schema.hasTable('final_entities');
    
    if (hasFinalEntitiesTable) {
      const userEntity = await knex('final_entities')
        .whereRaw("entity_ref = ?", [userEntityRef])
        .first();

      if (userEntity && userEntity.final_entity) {
        try {
          const entity = typeof userEntity.final_entity === 'string' 
            ? JSON.parse(userEntity.final_entity) 
            : userEntity.final_entity;
          
          const memberOf = entity?.spec?.memberOf || [];
          if (memberOf.includes('group:default/admins') || 
              memberOf.includes('admins')) {
            logger.debug(`User ${userEntityRef} is admin via memberOf spec`);
            return true;
          }
        } catch (e) {
          logger.debug('Could not parse user entity', e);
        }
      }
    }

    // Fallback: Check if username matches known admin patterns
    // This is a temporary measure - in production, rely on catalog data
    const adminUsernames = ['admin', 'administrator'];
    if (adminUsernames.includes(username.toLowerCase())) {
      logger.debug(`User ${username} is admin via username pattern`);
      return true;
    }

    logger.debug(`User ${userEntityRef} is not an admin`);
    return false;
  } catch (error) {
    logger.error('Error checking admin status', error);
    return false;
  }
}

export default brandingSettingsPlugin;
