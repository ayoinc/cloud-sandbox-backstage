/**
 * =============================================================================
 * Branding Settings Express Route Handlers
 * =============================================================================
 *
 * REST API route handlers for branding settings management.
 *
 * Endpoints:
 * - GET    /                  - Get current branding settings
 * - POST   /                  - Update branding settings (admin only)
 * - POST   /logo/upload       - Upload logo files (admin only)
 * - GET    /logo/:kind        - The uploaded full or icon logo (public)
 * - DELETE /logo              - Reset logo to default (admin only)
 * - DELETE /                  - Reset all branding to default (admin only)
 * - GET    /admin-check       - Check if current user is admin
 * - GET    /admins            - List branding admins (admin only)
 * - POST   /admins            - Add a branding admin (admin only)
 * - DELETE /admins/:id        - Remove a branding admin (admin only)
 *
 * =============================================================================
 */

import { Router, json, Request, Response } from 'express';
import multer from 'multer';
import type { Knex } from 'knex';
import type { LoggerService } from '@backstage/backend-plugin-api';
import { ALLOWED_MIME_TYPES, DEFAULT_SETTINGS } from './types';
import {
  getCurrentSettings,
  updateSettings,
  checkIsAdmin,
  getAdmins,
  addAdmin,
  removeAdmin,
  getAdminCount,
  getAdminById,
} from './database';
import {
  MAX_LOGO_BYTES,
  deleteLogos,
  isLogoKind,
  readLogo,
  saveLogo,
} from './storage';

/**
 * Dependencies for creating the router
 */
interface RouterDeps {
  knex: Knex;
  logger: LoggerService;
  httpAuth: any;
  userInfo: any;
}

/**
 * Multer configuration for file uploads
 */
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: MAX_LOGO_BYTES,
  },
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(
        new Error(
          'Invalid file type. Only PNG, JPEG, SVG, WebP, and GIF are allowed.',
        ),
      );
    }
  },
});

/**
 * Create the branding settings router with all endpoints
 */
export function createRouter(deps: RouterDeps): Router {
  const { knex, logger, httpAuth, userInfo } = deps;
  const router = Router();

  // Add JSON body parser middleware
  router.use(json());

  /**
   * Helper to check admin and get user ref
   */
  async function requireAdmin(
    req: Request,
    res: Response,
  ): Promise<string | null> {
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
    } catch {
      res.status(401).json({ error: 'Authentication required' });
      return null;
    }
  }

  // =======================================================================
  // GET / - Get current branding settings (public)
  // =======================================================================
  router.get('/', async (_req: Request, res: Response): Promise<void> => {
    try {
      const settings = await getCurrentSettings(knex);
      res.json(settings);
    } catch (error) {
      logger.error('Failed to get branding settings', error as Error);
      res.status(500).json({ error: 'Failed to get branding settings' });
    }
  });

  // =======================================================================
  // POST / - Update branding settings (admin only)
  // =======================================================================
  router.post('/', async (req: Request, res: Response): Promise<void> => {
    const userEntityRef = await requireAdmin(req, res);
    if (!userEntityRef) return;

    try {
      const {
        organizationName,
        primaryColor,
        themePreset,
        logoFullUrl,
        logoIconUrl,
      } = req.body;

      // A preset id, or null / '' to go back to the built-in theme
      if (
        themePreset !== undefined &&
        themePreset !== null &&
        themePreset !== '' &&
        (typeof themePreset !== 'string' ||
          !/^[a-z][a-z0-9-]{0,39}$/.test(themePreset))
      ) {
        res.status(400).json({
          error:
            'themePreset must be a preset id: lower-case letters, digits and dashes, at most 40',
        });
        return;
      }

      const updates: Record<string, unknown> = {
        updated_at: new Date().toISOString(),
        updated_by: userEntityRef,
      };

      if (organizationName !== undefined) {
        updates.organization_name = organizationName || null;
      }
      if (primaryColor !== undefined) {
        updates.primary_color = primaryColor || null;
      }
      if (themePreset !== undefined) {
        updates.theme_preset = themePreset || null;
      }
      if (logoFullUrl !== undefined) {
        updates.logo_full_url = logoFullUrl || null;
      }
      if (logoIconUrl !== undefined) {
        updates.logo_icon_url = logoIconUrl || null;
      }

      await updateSettings(knex, updates);
      logger.info(`Branding settings updated by ${userEntityRef}`);

      const newSettings = await getCurrentSettings(knex);
      res.json(newSettings);
    } catch (error) {
      logger.error('Failed to update branding settings', error as Error);
      res.status(500).json({ error: 'Failed to update branding settings' });
    }
  });

  // =======================================================================
  // POST /logo/upload - Upload logo files (admin only)
  // =======================================================================
  const uploadMiddleware = upload.fields([
    { name: 'logoFull', maxCount: 1 },
    { name: 'logoIcon', maxCount: 1 },
  ]);

  router.post(
    '/logo/upload',
    (req, res, next) => {
      uploadMiddleware(req as any, res as any, (error: unknown) => {
        if (!error) {
          next();
          return;
        }
        // An oversized or unsupported file is the sender's mistake.
        const tooLarge =
          error instanceof multer.MulterError &&
          error.code === 'LIMIT_FILE_SIZE';
        res.status(tooLarge ? 413 : 400).json({
          error: tooLarge
            ? 'A logo can be at most 1 MB.'
            : (error as Error).message,
        });
      });
    },
    async (req: Request, res: Response): Promise<void> => {
      const userEntityRef = await requireAdmin(req, res);
      if (!userEntityRef) return;

      try {
        const files = req.files as {
          [fieldname: string]: Express.Multer.File[];
        };
        const currentSettings = await getCurrentSettings(knex);

        let logoFullUrl = currentSettings.logoFullUrl;
        let logoIconUrl = currentSettings.logoIconUrl;

        if (files.logoFull && files.logoFull[0]) {
          logoFullUrl = await saveLogo(knex, 'full', files.logoFull[0]);
        }

        if (files.logoIcon && files.logoIcon[0]) {
          logoIconUrl = await saveLogo(knex, 'icon', files.logoIcon[0]);
        }

        await updateSettings(knex, {
          logo_full_url: logoFullUrl,
          logo_icon_url: logoIconUrl,
          updated_at: new Date().toISOString(),
          updated_by: userEntityRef,
        });

        logger.info(`Logo uploaded by ${userEntityRef}`);

        const newSettings = await getCurrentSettings(knex);
        res.json(newSettings);
      } catch (error) {
        logger.error('Failed to upload logo', error as Error);
        res.status(500).json({ error: 'Failed to upload logo' });
      }
    },
  );

  // =======================================================================
  // GET /logo/:kind - The uploaded logo (public: the sign-in page shows it)
  // =======================================================================
  router.get(
    '/logo/:kind',
    async (req: Request, res: Response): Promise<void> => {
      const { kind } = req.params;
      const logo = isLogoKind(kind) ? await readLogo(knex, kind) : undefined;
      if (!logo) {
        res.status(404).json({ error: 'No such logo' });
        return;
      }
      res
        .status(200)
        .set({
          'content-type': logo.contentType,
          // The address changes with every upload.
          'cache-control': 'public, max-age=31536000, immutable',
          'x-content-type-options': 'nosniff',
          // An uploaded SVG must not run script when opened on its own.
          'content-security-policy':
            "default-src 'none'; style-src 'unsafe-inline'; sandbox",
        })
        .send(logo.bytes);
    },
  );

  // =======================================================================
  // DELETE /logo - Reset logo to default (admin only)
  // =======================================================================
  router.delete('/logo', async (req: Request, res: Response): Promise<void> => {
    const userEntityRef = await requireAdmin(req, res);
    if (!userEntityRef) return;

    try {
      await deleteLogos(knex);

      await updateSettings(knex, {
        logo_full_url: null,
        logo_icon_url: null,
        updated_at: new Date().toISOString(),
        updated_by: userEntityRef,
      });

      logger.info(`Logo reset by ${userEntityRef}`);

      const newSettings = await getCurrentSettings(knex);
      res.json(newSettings);
    } catch (error) {
      logger.error('Failed to reset logo', error as Error);
      res.status(500).json({ error: 'Failed to reset logo' });
    }
  });

  // =======================================================================
  // DELETE / - Reset all branding to default (admin only)
  // =======================================================================
  router.delete('/', async (req: Request, res: Response): Promise<void> => {
    const userEntityRef = await requireAdmin(req, res);
    if (!userEntityRef) return;

    try {
      await deleteLogos(knex);

      await updateSettings(knex, {
        organization_name: null,
        logo_full_url: null,
        logo_icon_url: null,
        primary_color: null,
        theme_preset: null,
        updated_at: new Date().toISOString(),
        updated_by: userEntityRef,
      });

      logger.info(`All branding settings reset by ${userEntityRef}`);

      res.json(DEFAULT_SETTINGS);
    } catch (error) {
      logger.error('Failed to reset branding settings', error as Error);
      res.status(500).json({ error: 'Failed to reset branding settings' });
    }
  });

  // =======================================================================
  // GET /admin-check - Check if current user is admin
  // =======================================================================
  router.get(
    '/admin-check',
    async (req: Request, res: Response): Promise<void> => {
      try {
        const credentials = await httpAuth.credentials(req, {
          allow: ['user'],
        });

        const user = await userInfo.getUserInfo(credentials);
        const userEntityRef = user.userEntityRef;

        if (!userEntityRef) {
          res.json({ isAdmin: false });
          return;
        }

        const isAdmin = await checkIsAdmin(knex, userEntityRef, logger);
        res.json({ isAdmin, userEntityRef });
      } catch {
        res.json({ isAdmin: false });
      }
    },
  );

  // =======================================================================
  // GET /admins - List branding admins (admin only)
  // =======================================================================
  router.get('/admins', async (req: Request, res: Response): Promise<void> => {
    const userEntityRef = await requireAdmin(req, res);
    if (!userEntityRef) return;

    try {
      const admins = await getAdmins(knex);
      res.json({ admins });
    } catch (error) {
      logger.error('Failed to list branding admins', error as Error);
      res.status(500).json({ error: 'Failed to list admins' });
    }
  });

  // =======================================================================
  // POST /admins - Add a branding admin (admin only)
  // =======================================================================
  router.post('/admins', async (req: Request, res: Response): Promise<void> => {
    const userEntityRef = await requireAdmin(req, res);
    if (!userEntityRef) return;

    try {
      const { entityRef } = req.body;

      if (!entityRef || typeof entityRef !== 'string') {
        res.status(400).json({ error: 'entityRef is required' });
        return;
      }

      // Normalize entity ref
      let normalizedRef = entityRef.trim().toLowerCase();
      if (!normalizedRef.includes(':')) {
        normalizedRef = `user:default/${normalizedRef}`;
      }

      // Validate format
      if (!normalizedRef.match(/^(user|group):[^/]+\/.+$/)) {
        res.status(400).json({
          error:
            'Invalid entityRef format. Use user:default/username or group:default/teamname',
        });
        return;
      }

      // Check if already exists
      const existing = await knex('branding_admins')
        .where('entity_ref', normalizedRef)
        .first();

      if (existing) {
        res.status(409).json({ error: 'Admin already exists' });
        return;
      }

      await addAdmin(knex, normalizedRef, userEntityRef);
      logger.info(`Branding admin added: ${normalizedRef} by ${userEntityRef}`);

      const admins = await getAdmins(knex);
      res.json({ admins });
    } catch (error) {
      logger.error('Failed to add branding admin', error as Error);
      res.status(500).json({ error: 'Failed to add admin' });
    }
  });

  // =======================================================================
  // DELETE /admins/:id - Remove a branding admin (admin only)
  // =======================================================================
  router.delete(
    '/admins/:id',
    async (req: Request, res: Response): Promise<void> => {
      const userEntityRef = await requireAdmin(req, res);
      if (!userEntityRef) return;

      try {
        const { id } = req.params;
        const numId = parseInt(id, 10);

        const adminCount = await getAdminCount(knex);
        const targetAdmin = await getAdminById(knex, numId);

        if (!targetAdmin) {
          res.status(404).json({ error: 'Admin not found' });
          return;
        }

        if (adminCount <= 1) {
          res.status(400).json({ error: 'Cannot remove the last admin' });
          return;
        }

        if (targetAdmin.entity_ref === userEntityRef.toLowerCase()) {
          res.status(400).json({
            error: 'Cannot remove yourself. Ask another admin to remove you.',
          });
          return;
        }

        await removeAdmin(knex, numId);
        logger.info(
          `Branding admin removed: ${targetAdmin.entity_ref} by ${userEntityRef}`,
        );

        const admins = await getAdmins(knex);
        res.json({ admins });
      } catch (error) {
        logger.error('Failed to remove branding admin', error as Error);
        res.status(500).json({ error: 'Failed to remove admin' });
      }
    },
  );

  return router;
}
