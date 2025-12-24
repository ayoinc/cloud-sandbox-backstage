import {
  createBackendPlugin,
  coreServices,
} from '@backstage/backend-plugin-api';
import { Router, json } from 'express';
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

        // Get database client for branding settings storage
        const knex = await database.getClient();

        // Create branding_settings table if not exists
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

        // Create branding_admins table if not exists
        // This table stores users and groups that can manage branding settings
        const hasAdminsTable = await knex.schema.hasTable('branding_admins');
        if (!hasAdminsTable) {
          logger.info('Creating branding_admins table');
          await knex.schema.createTable('branding_admins', (table) => {
            table.increments('id').primary();
            table.string('entity_ref').notNullable().unique(); // user:default/username or group:default/team
            table.string('type').notNullable(); // 'user' or 'group'
            table.timestamp('added_at').defaultTo(knex.fn.now());
            table.string('added_by').nullable();
          });
          
          // Bootstrap initial admin from environment variable (only on first run)
          const initialAdmin = process.env.BRANDING_INITIAL_ADMIN || process.env.BRANDING_ADMIN_USERS?.split(',')[0]?.trim();
          if (initialAdmin) {
            const entityRef = initialAdmin.includes(':') ? initialAdmin : `user:default/${initialAdmin}`;
            await knex('branding_admins').insert({
              entity_ref: entityRef,
              type: entityRef.startsWith('group:') ? 'group' : 'user',
              added_at: new Date().toISOString(),
              added_by: 'system',
            });
            logger.info(`Bootstrapped initial branding admin: ${entityRef}`);
          } else {
            logger.warn('No initial branding admin configured. Set BRANDING_INITIAL_ADMIN env var.');
          }
        }

        // Initialize S3 client for MinIO
        // All credentials come from config or environment variables - no hardcoded secrets
        const minioEndpoint = config.getOptionalString('brandingSettings.minio.endpoint') 
          || process.env.MINIO_ENDPOINT 
          || 'http://minio:9000';
        const minioAccessKey = config.getOptionalString('brandingSettings.minio.accessKeyId')
          || process.env.MINIO_ACCESS_KEY;
        const minioSecretKey = config.getOptionalString('brandingSettings.minio.secretAccessKey')
          || process.env.MINIO_SECRET_KEY;
        const minioBucket = config.getOptionalString('brandingSettings.minio.bucket')
          || process.env.BRANDING_BUCKET
          || 'backstage-assets';
        if (!minioAccessKey || !minioSecretKey) {
          logger.warn('MinIO credentials not configured - logo upload will fail. Set MINIO_ACCESS_KEY and MINIO_SECRET_KEY environment variables.');
        }

        const s3Client = new S3Client({
          endpoint: minioEndpoint,
          region: 'us-east-1',
          credentials: {
            accessKeyId: minioAccessKey || '',
            secretAccessKey: minioSecretKey || '',
          },
          forcePathStyle: true, // Required for MinIO
        });

        logger.info(`Branding settings using MinIO at ${minioEndpoint}, bucket: ${minioBucket}`);

        const router = Router();
        
        // Add JSON body parser middleware
        router.use(json());

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

            // Use knex to check admin status
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

                // Use /assets/ path which is proxied by nginx to MinIO
                logoFullUrl = `/assets/${key}?t=${Date.now()}`;
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

                // Use /assets/ path which is proxied by nginx to MinIO
                logoIconUrl = `/assets/${key}?t=${Date.now()}`;
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

            // Use knex to check admin status
            const isAdmin = await checkIsAdmin(knex, userEntityRef, logger);
            return res.json({ isAdmin, userEntityRef });
          } catch (error) {
            return res.json({ isAdmin: false });
          }
        });

        // =======================================================================
        // GET /api/branding-settings/admins - List branding admins (admin only)
        // =======================================================================
        router.get('/admins', async (req, res) => {
          const userEntityRef = await requireAdmin(req, res);
          if (!userEntityRef) return;

          try {
            const admins = await knex('branding_admins')
              .select('id', 'entity_ref', 'type', 'added_at', 'added_by')
              .orderBy('added_at', 'asc');
            
            return res.json({ admins });
          } catch (error) {
            logger.error('Failed to list branding admins', error as Error);
            return res.status(500).json({ error: 'Failed to list admins' });
          }
        });

        // =======================================================================
        // POST /api/branding-settings/admins - Add a branding admin (admin only)
        // =======================================================================
        router.post('/admins', async (req, res) => {
          const userEntityRef = await requireAdmin(req, res);
          if (!userEntityRef) return;

          try {
            const { entityRef } = req.body;
            
            if (!entityRef || typeof entityRef !== 'string') {
              return res.status(400).json({ error: 'entityRef is required' });
            }

            // Normalize entity ref
            let normalizedRef = entityRef.trim().toLowerCase();
            if (!normalizedRef.includes(':')) {
              // Assume it's a username if no prefix
              normalizedRef = `user:default/${normalizedRef}`;
            }

            // Validate format
            if (!normalizedRef.match(/^(user|group):[^/]+\/.+$/)) {
              return res.status(400).json({ error: 'Invalid entityRef format. Use user:default/username or group:default/teamname' });
            }

            const type = normalizedRef.startsWith('group:') ? 'group' : 'user';

            // Check if already exists
            const existing = await knex('branding_admins')
              .where('entity_ref', normalizedRef)
              .first();
            
            if (existing) {
              return res.status(409).json({ error: 'Admin already exists' });
            }

            // Insert new admin
            await knex('branding_admins').insert({
              entity_ref: normalizedRef,
              type,
              added_at: new Date().toISOString(),
              added_by: userEntityRef,
            });

            logger.info(`Branding admin added: ${normalizedRef} by ${userEntityRef}`);

            const admins = await knex('branding_admins')
              .select('id', 'entity_ref', 'type', 'added_at', 'added_by')
              .orderBy('added_at', 'asc');
            
            return res.json({ admins });
          } catch (error) {
            logger.error('Failed to add branding admin', error as Error);
            return res.status(500).json({ error: 'Failed to add admin' });
          }
        });

        // =======================================================================
        // DELETE /api/branding-settings/admins/:id - Remove a branding admin (admin only)
        // =======================================================================
        router.delete('/admins/:id', async (req, res) => {
          const userEntityRef = await requireAdmin(req, res);
          if (!userEntityRef) return;

          try {
            const { id } = req.params;
            
            // Don't allow removing yourself if you're the last admin
            const adminCount = await knex('branding_admins').count('id as count').first();
            const targetAdmin = await knex('branding_admins').where('id', id).first();
            
            if (!targetAdmin) {
              return res.status(404).json({ error: 'Admin not found' });
            }

            if (parseInt(adminCount?.count as string, 10) <= 1) {
              return res.status(400).json({ error: 'Cannot remove the last admin' });
            }

            if (targetAdmin.entity_ref === userEntityRef.toLowerCase()) {
              return res.status(400).json({ error: 'Cannot remove yourself. Ask another admin to remove you.' });
            }

            await knex('branding_admins').where('id', id).delete();

            logger.info(`Branding admin removed: ${targetAdmin.entity_ref} by ${userEntityRef}`);

            const admins = await knex('branding_admins')
              .select('id', 'entity_ref', 'type', 'added_at', 'added_by')
              .orderBy('added_at', 'asc');
            
            return res.json({ admins });
          } catch (error) {
            logger.error('Failed to remove branding admin', error as Error);
            return res.status(500).json({ error: 'Failed to remove admin' });
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
 * Check if user is an admin for branding settings.
 * 
 * Checks the branding_admins table for:
 * 1. Direct user match (user:default/username)
 * 2. Group match (group:default/team) - user must be member of that group
 * 
 * Falls back to BRANDING_ADMIN_USERS env var if database is empty.
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
      logger.debug(`Invalid user entity ref format: ${userEntityRef}`);
      return false;
    }

    const [, , username] = match;

    // Check branding_admins table for direct user match
    const directMatch = await knex('branding_admins')
      .where('entity_ref', userEntityRef.toLowerCase())
      .first();
    
    if (directMatch) {
      logger.debug(`User ${username} is admin via branding_admins table`);
      return true;
    }

    // Check for group-based admin (would need catalog integration for full support)
    // For now, just check if any group entries exist and log
    const groupAdmins = await knex('branding_admins')
      .where('type', 'group')
      .select('entity_ref');
    
    if (groupAdmins.length > 0) {
      logger.debug(`Group-based admins configured: ${groupAdmins.map((g: any) => g.entity_ref).join(', ')}`);
      // TODO: Check catalog for user's group membership
    }

    // Fallback: Check BRANDING_ADMIN_USERS env var (for backwards compatibility)
    const adminUsersEnv = process.env.BRANDING_ADMIN_USERS || '';
    const adminUsernames = adminUsersEnv
      .split(',')
      .map(u => u.trim().toLowerCase())
      .filter(u => u.length > 0);
    
    if (adminUsernames.includes(username.toLowerCase())) {
      logger.debug(`User ${username} is admin via BRANDING_ADMIN_USERS env var`);
      return true;
    }

    logger.debug(`User ${userEntityRef} is not a branding admin`);
    return false;
  } catch (error) {
    logger.error('Error checking admin status', error);
    return false;
  }
}

export default brandingSettingsPlugin;
