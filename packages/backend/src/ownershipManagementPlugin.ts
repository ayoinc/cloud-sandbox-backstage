import {
  createBackendPlugin,
  coreServices,
  type HttpAuthService,
} from '@backstage/backend-plugin-api';
import type { Entity } from '@backstage/catalog-model';
import { catalogServiceRef } from '@backstage/plugin-catalog-node';
import { ACCOUNT_ANNOTATION, directory } from './accounts/directory';
import { Router } from 'express';
import * as express from 'express';

/**
 * =============================================================================
 * Ownership Management Backend Plugin
 * =============================================================================
 *
 * Handles orphaned entity detection and ownership reassignment.
 *
 * FEATURES:
 * - Detects orphaned entities (owned by non-existent groups)
 * - Logs warnings when orphans are detected
 * - Provides API endpoints for manual ownership reassignment
 * - Stores ownership overrides in database for catalog-managed entities
 * - Works with GitHub team sync - when a team is deleted in GitHub,
 *   the GithubOrgEntityProvider removes the group, and this plugin
 *   detects any entities that were owned by that group
 *
 * API ENDPOINTS (portal administrators only; each lists and changes only
 * shared entities and those of the caller's own accounts):
 * - GET /api/ownership-management/orphans - List all orphaned entities
 * - GET /api/ownership-management/groups - List all groups for reassignment dropdown
 * - GET /api/ownership-management/entities - List all ownable entities
 * - POST /api/ownership-management/reassign - Reassign ownership of an entity
 * - GET /api/ownership-management/overrides - Get all ownership overrides
 *
 * SCHEDULED TASKS:
 * - Runs every 10 minutes to detect and handle orphaned entities
 *
 * =============================================================================
 */

interface OrphanedEntity {
  entityRef: string;
  kind: string;
  name: string;
  namespace: string;
  currentOwner: string;
  title?: string;
}

interface GroupInfo {
  name: string;
  displayName: string;
  description?: string;
  entityRef: string;
}

interface OwnershipOverride {
  entityRef: string;
  newOwner: string;
  previousOwner: string;
  overriddenAt: string;
  overriddenBy: string;
}

export const ownershipManagementPlugin = createBackendPlugin({
  pluginId: 'ownership-management',
  register(env) {
    env.registerInit({
      deps: {
        logger: coreServices.logger,
        config: coreServices.rootConfig,
        scheduler: coreServices.scheduler,
        catalog: catalogServiceRef,
        auth: coreServices.auth,
        httpRouter: coreServices.httpRouter,
        database: coreServices.database,
        httpAuth: coreServices.httpAuth,
        userInfo: coreServices.userInfo,
      },
      async init({
        logger,
        scheduler,
        catalog,
        auth,
        httpRouter,
        database,
        httpAuth,
        userInfo,
      }) {
        const DEFAULT_ORPHAN_GROUP = 'unassigned';

        // Track last orphan count to avoid duplicate log spam
        let lastOrphanCount = 0;

        // Get database client and initialize tables
        const knex = await database.getClient();

        // Create ownership_overrides table if not exists
        const hasTable = await knex.schema.hasTable('ownership_overrides');
        if (!hasTable) {
          logger.info('Creating ownership_overrides table');
          await knex.schema.createTable('ownership_overrides', table => {
            table.string('entity_ref').primary();
            table.string('new_owner').notNullable();
            table.string('previous_owner').nullable();
            table.timestamp('overridden_at').defaultTo(knex.fn.now());
            table.string('overridden_by').nullable();
          });
        }

        // Helper: Get ownership override for an entity
        async function getOwnershipOverride(
          entityRef: string,
        ): Promise<OwnershipOverride | null> {
          const row = await knex('ownership_overrides')
            .where('entity_ref', entityRef.toLowerCase())
            .first();

          if (!row) return null;

          return {
            entityRef: row.entity_ref,
            newOwner: row.new_owner,
            previousOwner: row.previous_owner,
            overriddenAt: row.overridden_at,
            overriddenBy: row.overridden_by,
          };
        }

        // Helper: Get all ownership overrides
        async function getAllOverrides(): Promise<OwnershipOverride[]> {
          const rows = await knex('ownership_overrides')
            .select('*')
            .orderBy('overridden_at', 'desc');

          return rows.map((row: any) => ({
            entityRef: row.entity_ref,
            newOwner: row.new_owner,
            previousOwner: row.previous_owner,
            overriddenAt: row.overridden_at,
            overriddenBy: row.overridden_by,
          }));
        }

        // Helper: Get all ownership overrides as a Map for fast lookup
        async function getAllOverridesMap(): Promise<
          Map<string, OwnershipOverride>
        > {
          const overrides = await getAllOverrides();
          const map = new Map<string, OwnershipOverride>();
          for (const override of overrides) {
            map.set(override.entityRef.toLowerCase(), override);
          }
          return map;
        }

        // Helper: Set ownership override
        async function setOwnershipOverride(
          entityRef: string,
          newOwner: string,
          previousOwner: string,
          overriddenBy: string,
        ): Promise<void> {
          await knex('ownership_overrides')
            .insert({
              entity_ref: entityRef.toLowerCase(),
              new_owner: newOwner,
              previous_owner: previousOwner,
              overridden_at: new Date().toISOString(),
              overridden_by: overriddenBy,
            })
            .onConflict('entity_ref')
            .merge([
              'new_owner',
              'previous_owner',
              'overridden_at',
              'overridden_by',
            ]);
        }

        // Helper: whether an entity is shared, or belongs to one of
        // `accounts`. Without `accounts` (the scheduled check) every entity
        // counts.
        function isWithin(entity: Entity, accounts?: string[]): boolean {
          const account = entity.metadata.annotations?.[ACCOUNT_ANNOTATION];
          return (
            accounts === undefined ||
            account === undefined ||
            accounts.includes(account)
          );
        }

        // Helper: Get all groups
        async function getAllGroups(
          accounts?: string[],
        ): Promise<Map<string, GroupInfo>> {
          const groups = new Map<string, GroupInfo>();
          try {
            const entities = await catalog.getEntities(
              { filter: { kind: 'Group' } },
              { credentials: await auth.getOwnServiceCredentials() },
            );

            for (const entity of entities.items) {
              if (!isWithin(entity, accounts)) {
                continue;
              }
              const name = entity.metadata.name;
              const namespace = entity.metadata.namespace || 'default';
              const entityRef = `group:${namespace}/${name}`;

              groups.set(entityRef.toLowerCase(), {
                name,
                displayName: (entity.spec as any)?.profile?.displayName || name,
                description: entity.metadata.description,
                entityRef,
              });
            }
          } catch (error) {
            logger.error('Failed to fetch groups', error as Error);
          }
          return groups;
        }

        // Helper: Get effective owner (considering overrides) - for single entity lookup
        async function getEffectiveOwner(
          entityRef: string,
          catalogOwner: string,
        ): Promise<string> {
          const override = await getOwnershipOverride(entityRef);
          return override ? override.newOwner : catalogOwner;
        }

        // Helper: Get effective owner using pre-loaded overrides map - for bulk operations
        function getEffectiveOwnerFromMap(
          entityRef: string,
          catalogOwner: string,
          overridesMap: Map<string, OwnershipOverride>,
        ): string {
          const override = overridesMap.get(entityRef.toLowerCase());
          return override ? override.newOwner : catalogOwner;
        }

        // Helper: Get all ownable entities - optimized to avoid N+1 queries
        async function getOwnableEntities(
          accounts?: string[],
        ): Promise<OrphanedEntity[]> {
          const ownableKinds = [
            'Component',
            'API',
            'Resource',
            'System',
            'Domain',
          ];
          const entities: OrphanedEntity[] = [];

          try {
            // Fetch all overrides once upfront to avoid N+1 queries
            const overridesMap = await getAllOverridesMap();

            // Fetch all kinds in parallel instead of sequentially
            const credentials = await auth.getOwnServiceCredentials();
            const kindResults = await Promise.all(
              ownableKinds.map(kind =>
                catalog
                  .getEntities({ filter: { kind } }, { credentials })
                  .then(result => ({
                    kind,
                    items: result.items,
                  })),
              ),
            );

            for (const { kind, items } of kindResults) {
              for (const entity of items) {
                const catalogOwner = (entity.spec as any)?.owner;
                if (catalogOwner && isWithin(entity, accounts)) {
                  const entityRef = `${kind.toLowerCase()}:${
                    entity.metadata.namespace || 'default'
                  }/${entity.metadata.name}`;
                  const effectiveOwner = getEffectiveOwnerFromMap(
                    entityRef,
                    catalogOwner,
                    overridesMap,
                  );

                  entities.push({
                    entityRef,
                    kind,
                    name: entity.metadata.name,
                    namespace: entity.metadata.namespace || 'default',
                    currentOwner: effectiveOwner,
                    title: entity.metadata.title,
                  });
                }
              }
            }
          } catch (error) {
            logger.error('Failed to fetch ownable entities', error as Error);
          }
          return entities;
        }

        // Helper: Normalize owner reference
        function normalizeOwnerRef(owner: string): string {
          let ownerRef = owner.toLowerCase();

          if (!ownerRef.includes(':')) {
            // Simple name like "platform-team" - assume it's a group
            ownerRef = `group:default/${ownerRef}`;
          } else if (!ownerRef.includes('/')) {
            // Format like "group:platform-team" - add default namespace
            const [kind, name] = ownerRef.split(':');
            ownerRef = `${kind}:default/${name}`;
          }

          return ownerRef;
        }

        // Helper: Find orphaned entities
        async function findOrphanedEntities(
          accounts?: string[],
        ): Promise<OrphanedEntity[]> {
          // Fetch groups and entities in parallel
          const [groups, entities] = await Promise.all([
            getAllGroups(accounts),
            getOwnableEntities(accounts),
          ]);
          const orphans: OrphanedEntity[] = [];

          for (const entity of entities) {
            const ownerRef = normalizeOwnerRef(entity.currentOwner);

            // Check if owner exists
            if (!groups.has(ownerRef)) {
              // Also check for user owners
              if (!ownerRef.startsWith('user:')) {
                orphans.push(entity);
              }
            }
          }

          return orphans;
        }

        // Helper: Reassign orphaned entities to unassigned group
        async function detectAndNotifyOrphans(): Promise<number> {
          const orphans = await findOrphanedEntities();

          if (orphans.length === 0) {
            if (lastOrphanCount > 0) {
              // All orphans have been resolved
              logger.info('All orphaned entities have been resolved');
              lastOrphanCount = 0;
            }
            return 0;
          }

          logger.info(`Found ${orphans.length} orphaned entities`);

          // Check if unassigned group exists
          const groups = await getAllGroups();
          const unassignedRef = `group:default/${DEFAULT_ORPHAN_GROUP}`;

          if (!groups.has(unassignedRef.toLowerCase())) {
            logger.warn(
              `Default orphan group '${DEFAULT_ORPHAN_GROUP}' not found - create it to enable orphan handling`,
            );
          }

          // Log if orphan count increased
          if (orphans.length > lastOrphanCount) {
            const newOrphans = orphans.length - lastOrphanCount;
            logger.warn(
              `ALERT: ${newOrphans} new orphaned entities detected! Total: ${orphans.length}`,
            );
            logger.warn('Visit /admin/ownership to reassign orphaned entities');
          }

          // Log each orphan
          for (const orphan of orphans) {
            logger.warn(
              `Orphaned entity: ${orphan.entityRef} (owner: ${orphan.currentOwner}) - needs reassignment`,
            );
          }

          lastOrphanCount = orphans.length;
          return orphans.length;
        }

        // Create API router
        const router = Router();
        router.use(express.json());

        // Every route is for portal administrators, and works within the
        // caller's accounts.
        router.use(async (req, res, next) => {
          let caller;
          try {
            // Backstage types its services against Express 4; this is Express 5.
            const request = req as unknown as Parameters<
              HttpAuthService['credentials']
            >[0];
            const credentials = await httpAuth.credentials(request, {
              allow: ['user'],
            });
            caller = await userInfo.getUserInfo(credentials);
          } catch {
            res.status(401).json({ error: 'Authentication required' });
            return;
          }
          try {
            // No groups: the ones a sign-in names can come from a catalog
            // file the person registered themselves.
            const isAdmin = await directory.isPortalAdmin(
              caller.userEntityRef,
              [],
            );
            if (!isAdmin) {
              res.status(403).json({
                error: 'Only a portal administrator can manage ownership',
              });
              return;
            }
            res.locals.user = caller.userEntityRef;
            res.locals.accounts = await directory.accountsOf(
              caller.userEntityRef,
            );
            next();
          } catch (error) {
            logger.error('Failed to check the caller', error as Error);
            res.status(500).json({ error: 'Failed to check the caller' });
          }
        });

        // GET /api/ownership/orphans - List orphaned entities
        router.get('/orphans', async (_req, res) => {
          try {
            const orphans = await findOrphanedEntities(res.locals.accounts);
            res.json({
              count: orphans.length,
              orphans,
            });
          } catch (error) {
            logger.error('Failed to get orphaned entities', error as Error);
            res.status(500).json({ error: 'Failed to get orphaned entities' });
          }
        });

        // GET /api/ownership/groups - List all groups
        router.get('/groups', async (_req, res) => {
          try {
            const groups = await getAllGroups(res.locals.accounts);
            const groupList = Array.from(groups.values()).sort((a, b) =>
              a.displayName.localeCompare(b.displayName),
            );
            res.json({
              count: groupList.length,
              groups: groupList,
            });
          } catch (error) {
            logger.error('Failed to get groups', error as Error);
            res.status(500).json({ error: 'Failed to get groups' });
          }
        });

        // GET /api/ownership/entities - List all ownable entities with their owners
        router.get('/entities', async (_req, res) => {
          try {
            // Fetch entities and groups in parallel
            const [entities, groups] = await Promise.all([
              getOwnableEntities(res.locals.accounts),
              getAllGroups(res.locals.accounts),
            ]);

            // Enrich with owner validity
            const enrichedEntities = entities.map(entity => {
              const ownerRef = normalizeOwnerRef(entity.currentOwner);
              return {
                ...entity,
                ownerExists:
                  groups.has(ownerRef) || ownerRef.startsWith('user:'),
              };
            });

            res.json({
              count: enrichedEntities.length,
              entities: enrichedEntities,
            });
          } catch (error) {
            logger.error('Failed to get entities', error as Error);
            res.status(500).json({ error: 'Failed to get entities' });
          }
        });

        // GET /api/ownership/overrides - Get all ownership overrides
        router.get('/overrides', async (_req, res) => {
          try {
            // Only the overrides of entities the caller may see
            const within = new Set(
              (await getOwnableEntities(res.locals.accounts)).map(entity =>
                entity.entityRef.toLowerCase(),
              ),
            );
            const overrides = (await getAllOverrides()).filter(override =>
              within.has(override.entityRef.toLowerCase()),
            );
            res.json({
              count: overrides.length,
              overrides,
            });
          } catch (error) {
            logger.error('Failed to get ownership overrides', error as Error);
            res
              .status(500)
              .json({ error: 'Failed to get ownership overrides' });
          }
        });

        // POST /api/ownership/reassign - Reassign entity ownership
        router.post('/reassign', async (req, res) => {
          try {
            const { entityRef, newOwner } = req.body;

            if (!entityRef || !newOwner) {
              res
                .status(400)
                .json({ error: 'entityRef and newOwner are required' });
              return;
            }

            // The caller, for audit
            const currentUser: string = res.locals.user;
            const accounts: string[] = res.locals.accounts;

            // Verify the new owner exists
            const groups = await getAllGroups(accounts);
            const normalizedNewOwner = normalizeOwnerRef(newOwner);

            if (!groups.has(normalizedNewOwner)) {
              res
                .status(400)
                .json({ error: `Owner group '${newOwner}' not found` });
              return;
            }

            // Get the entity to verify it exists and get current owner
            try {
              const credentials = await auth.getOwnServiceCredentials();
              const entity = await catalog.getEntityByRef(entityRef, {
                credentials,
              });
              if (!entity || !isWithin(entity, accounts)) {
                res
                  .status(404)
                  .json({ error: `Entity '${entityRef}' not found` });
                return;
              }

              const catalogOwner = (entity.spec as any)?.owner || 'unknown';
              const previousOwner = await getEffectiveOwner(
                entityRef,
                catalogOwner,
              );

              // Store the ownership override in the database
              await setOwnershipOverride(
                entityRef,
                normalizedNewOwner,
                previousOwner,
                currentUser,
              );

              logger.info(
                `Ownership reassigned: ${entityRef} from ${previousOwner} to ${normalizedNewOwner} by ${currentUser}`,
              );

              // Trigger a catalog refresh for this entity to pick up the change
              try {
                await catalog.refreshEntity(entityRef, { credentials });
                logger.info(`Triggered catalog refresh for ${entityRef}`);
              } catch (refreshError) {
                logger.warn(
                  `Could not trigger catalog refresh for ${entityRef}:`,
                  refreshError as Error,
                );
              }

              res.json({
                success: true,
                message: `Ownership of ${entityRef} has been reassigned to ${normalizedNewOwner}`,
                entityRef,
                previousOwner,
                newOwner: normalizedNewOwner,
                overriddenBy: currentUser,
                overriddenAt: new Date().toISOString(),
              });
            } catch (error) {
              res
                .status(404)
                .json({ error: `Entity '${entityRef}' not found` });
              return;
            }
          } catch (error) {
            logger.error('Failed to reassign ownership', error as Error);
            res.status(500).json({ error: 'Failed to reassign ownership' });
          }
        });

        // DELETE /api/ownership/overrides - Remove an ownership override
        // entityRef is passed as a query parameter since it contains slashes (e.g., component:default/my-app)
        router.delete('/overrides', async (req, res) => {
          try {
            const entityRef = req.query.entityRef as string;

            if (!entityRef) {
              res
                .status(400)
                .json({ error: 'entityRef query parameter is required' });
              return;
            }

            const currentUser: string = res.locals.user;

            // An override of an entity outside the caller's accounts
            // answers as one that is not there.
            const existing = await getOwnershipOverride(entityRef);
            const entity = existing
              ? await catalog.getEntityByRef(entityRef, {
                  credentials: await auth.getOwnServiceCredentials(),
                })
              : undefined;
            if (
              !existing ||
              !entity ||
              !isWithin(entity, res.locals.accounts)
            ) {
              res.status(404).json({ error: 'Override not found' });
              return;
            }

            await knex('ownership_overrides')
              .where('entity_ref', entityRef.toLowerCase())
              .delete();

            logger.info(
              `Ownership override removed for ${entityRef} by ${currentUser}`,
            );

            res.json({
              success: true,
              message: `Ownership override removed for ${entityRef}`,
              entityRef,
              previousOverride: existing,
            });
          } catch (error) {
            logger.error('Failed to remove ownership override', error as Error);
            res
              .status(500)
              .json({ error: 'Failed to remove ownership override' });
          }
        });

        // Register the router
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        httpRouter.use(router as any);

        // Schedule orphan detection task
        await scheduler.scheduleTask({
          id: 'ownership-orphan-detection',
          frequency: { minutes: 10 },
          timeout: { minutes: 5 },
          initialDelay: { seconds: 60 },
          fn: async () => {
            logger.info('Running orphan detection...');
            const orphanCount = await detectAndNotifyOrphans();
            if (orphanCount > 0) {
              logger.warn(
                `Found ${orphanCount} orphaned entities - review at /admin/ownership`,
              );
            } else {
              logger.info('No orphaned entities found');
            }
          },
        });

        logger.info('Ownership Management plugin initialized');
        logger.info('API endpoints available at /api/ownership-management/*');
      },
    });
  },
});

export default ownershipManagementPlugin;
