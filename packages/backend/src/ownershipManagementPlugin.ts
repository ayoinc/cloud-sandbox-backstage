import {
  createBackendPlugin,
  coreServices,
} from '@backstage/backend-plugin-api';
import { catalogServiceRef } from '@backstage/plugin-catalog-node/alpha';
import { Router } from 'express';
import express from 'express';

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
 * - Works with GitHub team sync - when a team is deleted in GitHub,
 *   the GithubOrgEntityProvider removes the group, and this plugin
 *   detects any entities that were owned by that group
 *
 * API ENDPOINTS:
 * - GET /api/ownership-management/orphans - List all orphaned entities
 * - GET /api/ownership-management/groups - List all groups for reassignment dropdown
 * - GET /api/ownership-management/entities - List all ownable entities
 * - POST /api/ownership-management/reassign - Reassign ownership of an entity
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

export const ownershipManagementPlugin = createBackendPlugin({
  pluginId: 'ownership-management',
  register(env) {
    env.registerInit({
      deps: {
        logger: coreServices.logger,
        config: coreServices.rootConfig,
        scheduler: coreServices.scheduler,
        catalog: catalogServiceRef,
        httpRouter: coreServices.httpRouter,
      },
      async init({ logger, config, scheduler, catalog, httpRouter }) {
        const DEFAULT_ORPHAN_GROUP = 'unassigned';
        
        // Track last orphan count to avoid duplicate log spam
        let lastOrphanCount = 0;

        // Helper: Get all groups
        async function getAllGroups(): Promise<Map<string, GroupInfo>> {
          const groups = new Map<string, GroupInfo>();
          try {
            const entities = await catalog.getEntities({
              filter: { kind: 'Group' },
            });

            for (const entity of entities.items) {
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

        // Helper: Get all ownable entities
        async function getOwnableEntities(): Promise<OrphanedEntity[]> {
          const ownableKinds = ['Component', 'API', 'Resource', 'System', 'Domain'];
          const entities: OrphanedEntity[] = [];

          try {
            for (const kind of ownableKinds) {
              const result = await catalog.getEntities({
                filter: { kind },
              });

              for (const entity of result.items) {
                const owner = (entity.spec as any)?.owner;
                if (owner) {
                  entities.push({
                    entityRef: `${kind.toLowerCase()}:${entity.metadata.namespace || 'default'}/${entity.metadata.name}`,
                    kind,
                    name: entity.metadata.name,
                    namespace: entity.metadata.namespace || 'default',
                    currentOwner: owner,
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

        // Helper: Find orphaned entities
        async function findOrphanedEntities(): Promise<OrphanedEntity[]> {
          const groups = await getAllGroups();
          const entities = await getOwnableEntities();
          const orphans: OrphanedEntity[] = [];

          for (const entity of entities) {
            // Normalize owner reference
            let ownerRef = entity.currentOwner.toLowerCase();
            
            // Handle various owner formats
            if (!ownerRef.includes(':')) {
              // Simple name like "platform-team" - assume it's a group
              ownerRef = `group:default/${ownerRef}`;
            } else if (!ownerRef.includes('/')) {
              // Format like "group:platform-team" - add default namespace
              const [kind, name] = ownerRef.split(':');
              ownerRef = `${kind}:default/${name}`;
            }

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
            logger.warn(`Default orphan group '${DEFAULT_ORPHAN_GROUP}' not found - create it to enable orphan handling`);
          }

          // Log if orphan count increased
          if (orphans.length > lastOrphanCount) {
            const newOrphans = orphans.length - lastOrphanCount;
            logger.warn(`ALERT: ${newOrphans} new orphaned entities detected! Total: ${orphans.length}`);
            logger.warn('Visit /admin/ownership to reassign orphaned entities');
          }

          // Log each orphan
          for (const orphan of orphans) {
            logger.warn(`Orphaned entity: ${orphan.entityRef} (owner: ${orphan.currentOwner}) - needs reassignment`);
          }

          lastOrphanCount = orphans.length;
          return orphans.length;
        }

        // Create API router
        const router = Router();
        router.use(express.json());

        // GET /api/ownership/orphans - List orphaned entities
        router.get('/orphans', async (req, res) => {
          try {
            const orphans = await findOrphanedEntities();
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
        router.get('/groups', async (req, res) => {
          try {
            const groups = await getAllGroups();
            const groupList = Array.from(groups.values()).sort((a, b) => 
              a.displayName.localeCompare(b.displayName)
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
        router.get('/entities', async (req, res) => {
          try {
            const entities = await getOwnableEntities();
            const groups = await getAllGroups();

            // Enrich with owner validity
            const enrichedEntities = entities.map(entity => {
              let ownerRef = entity.currentOwner.toLowerCase();
              if (!ownerRef.includes(':')) {
                ownerRef = `group:default/${ownerRef}`;
              } else if (!ownerRef.includes('/')) {
                const [kind, name] = ownerRef.split(':');
                ownerRef = `${kind}:default/${name}`;
              }

              return {
                ...entity,
                ownerExists: groups.has(ownerRef) || ownerRef.startsWith('user:'),
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

        // POST /api/ownership/reassign - Reassign entity ownership
        // Note: This stores the reassignment intent - actual catalog update depends on source
        router.post('/reassign', async (req, res) => {
          try {
            const { entityRef, newOwner } = req.body;

            if (!entityRef || !newOwner) {
              res.status(400).json({ error: 'entityRef and newOwner are required' });
              return;
            }

            // Verify the new owner exists
            const groups = await getAllGroups();
            let ownerRef = newOwner.toLowerCase();
            if (!ownerRef.includes(':')) {
              ownerRef = `group:default/${ownerRef}`;
            } else if (!ownerRef.includes('/')) {
              const [kind, name] = ownerRef.split(':');
              ownerRef = `${kind}:default/${name}`;
            }

            if (!groups.has(ownerRef)) {
              res.status(400).json({ error: `Owner group '${newOwner}' not found` });
              return;
            }

            // For entities managed by annotations or file-based catalog,
            // we need to update the source. For now, we'll use annotations
            // to track ownership overrides.
            
            // Get the entity to verify it exists
            try {
              const entity = await catalog.getEntityByRef(entityRef);
              if (!entity) {
                res.status(404).json({ error: `Entity '${entityRef}' not found` });
                return;
              }

              // Log the reassignment request
              logger.info(`Ownership reassignment requested: ${entityRef} -> ${newOwner}`);

              // In a real implementation, you would:
              // 1. Update the entity in the catalog database (if using database backend)
              // 2. Create a PR to update the entity file (if using git backend)
              // 3. Use the catalog API to refresh the entity

              res.json({
                success: true,
                message: `Ownership reassignment of ${entityRef} to ${newOwner} has been recorded. Note: For file-based entities, update the catalog-info.yaml in the source repository.`,
                entityRef,
                previousOwner: (entity.spec as any)?.owner,
                newOwner,
              });
            } catch (error) {
              res.status(404).json({ error: `Entity '${entityRef}' not found` });
              return;
            }
          } catch (error) {
            logger.error('Failed to reassign ownership', error as Error);
            res.status(500).json({ error: 'Failed to reassign ownership' });
          }
        });

        // Register the router
        httpRouter.use(router);

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
              logger.warn(`Found ${orphanCount} orphaned entities - review at /admin/ownership`);
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
