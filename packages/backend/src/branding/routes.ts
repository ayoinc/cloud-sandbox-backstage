/**
 * =============================================================================
 * Portal Admins Express Route Handlers
 * =============================================================================
 *
 * REST API route handlers for portal admin management. Branding now belongs
 * to organisations (see ../organisations).
 *
 * Endpoints:
 * - GET    /admin-check       - Check if current user is admin
 * - GET    /admins            - List portal admins (admin only)
 * - POST   /admins            - Add a portal admin (admin only)
 * - DELETE /admins/:id        - Remove a portal admin (admin only)
 *
 * =============================================================================
 */

import { Router, json, Request, Response } from 'express';
import type { Knex } from 'knex';
import type { LoggerService } from '@backstage/backend-plugin-api';
import {
  checkIsAdmin,
  claimFirstAdmin,
  getAdmins,
  addAdmin,
  removeAdmin,
  getAdminCount,
  getAdminById,
} from './database';

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
 * Create the portal admins router with all endpoints
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

        const isAdmin =
          (await checkIsAdmin(knex, userEntityRef, logger)) ||
          (await claimFirstAdmin(knex, userEntityRef));
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
