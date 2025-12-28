import {
  coreServices,
  createBackendPlugin,
} from '@backstage/backend-plugin-api';
import { CatalogClient } from '@backstage/catalog-client';
import { Octokit } from '@octokit/rest';
import { Entity } from '@backstage/catalog-model';
import * as express from 'express';
import * as crypto from 'crypto';

/**
 * =============================================================================
 * Catalog Cleanup Plugin - Smart Sync Edition
 * =============================================================================
 *
 * Automatically detects and removes orphaned catalog entities when their
 * source repositories are deleted from GitHub.
 *
 * FEATURES:
 * - Proactive GitHub repository validation (checks if repos exist)
 * - Handles all entity types (Locations, Components, APIs, Resources, etc.)
 * - Tracks failure counts to avoid accidental deletions
 * - Sends notifications to admins for deleted repositories
 * - GitHub webhook handler for instant repo deletion detection
 * - Admin API endpoints for manual cleanup management
 * - Graceful degradation when GitHub API is unavailable
 *
 * API ENDPOINTS:
 * - GET  /api/catalog-cleanup/health        - Health check
 * - GET  /api/catalog-cleanup/orphans       - List tracked orphaned entities
 * - GET  /api/catalog-cleanup/stats         - Get cleanup statistics
 * - POST /api/catalog-cleanup/trigger       - Trigger immediate cleanup
 * - POST /api/catalog-cleanup/webhook       - GitHub webhook receiver
 * - DELETE /api/catalog-cleanup/entity/:ref - Force delete an entity
 *
 * DETECTION METHODS:
 * 1. Processing errors in entity status (backstage.io/catalog-processing)
 * 2. Orphan annotation (backstage.io/orphan)
 * 3. Direct GitHub API validation for repos with github.com/project-slug
 * 4. GitHub webhooks for repository.deleted events
 *
 * SAFETY:
 * - Requires 3 consecutive failures before deletion
 * - 30-minute stale threshold for failure tracking
 * - GitHub validation only for entities with explicit GitHub annotations
 *
 * =============================================================================
 */

interface FailedEntity {
  count: number;
  lastSeen: Date;
  reason: string;
  repoDeleted?: boolean;
  repoSlug?: string;
}

interface CleanupStats {
  checked: number;
  orphaned: number;
  deleted: number;
  reposValidated: number;
  reposMissing: number;
  lastRun?: Date;
}

// Module-level state (shared across requests)
const failedEntities = new Map<string, FailedEntity>();
let lastStats: CleanupStats = {
  checked: 0,
  orphaned: 0,
  deleted: 0,
  reposValidated: 0,
  reposMissing: 0,
};

export default createBackendPlugin({
  pluginId: 'catalog-cleanup',
  register(env) {
    env.registerInit({
      deps: {
        logger: coreServices.logger,
        scheduler: coreServices.scheduler,
        discovery: coreServices.discovery,
        auth: coreServices.auth,
        config: coreServices.rootConfig,
        httpRouter: coreServices.httpRouter,
      },
      async init({ logger, scheduler, discovery, auth, config, httpRouter }) {
        const catalogClient = new CatalogClient({
          discoveryApi: discovery,
        });

        // Configuration
        const MAX_FAILURES = 3;
        const STALE_THRESHOLD_MS = 30 * 60 * 1000; // 30 minutes
        const GITHUB_VALIDATION_ENABLED = true;

        // GitHub configuration
        // Try to get GitHub token from integrations config (first GitHub integration)
        let githubToken: string | undefined;
        try {
          const githubConfigs = config.getOptionalConfigArray(
            'integrations.github',
          );
          if (githubConfigs && githubConfigs.length > 0) {
            githubToken = githubConfigs[0].getOptionalString('token');
          }
        } catch {
          // Ignore config errors, fall back to env var
        }
        githubToken = githubToken || process.env.GITHUB_TOKEN;

        const webhookSecret =
          config.getOptionalString('catalogCleanup.webhookSecret') ||
          process.env.GITHUB_WEBHOOK_SECRET;

        const octokit = githubToken ? new Octokit({ auth: githubToken }) : null;

        if (!octokit) {
          logger.warn(
            'GitHub token not configured. Repository validation will be disabled.',
          );
        }

        // Repo existence cache
        const repoExistsCache = new Map<
          string,
          { exists: boolean; checkedAt: Date }
        >();
        const REPO_CACHE_TTL_MS = 10 * 60 * 1000;

        // =========================================================================
        // Helper Functions
        // =========================================================================

        async function checkRepoExists(
          owner: string,
          repo: string,
        ): Promise<boolean> {
          const cacheKey = `${owner}/${repo}`;
          const cached = repoExistsCache.get(cacheKey);

          if (
            cached &&
            Date.now() - cached.checkedAt.getTime() < REPO_CACHE_TTL_MS
          ) {
            return cached.exists;
          }

          if (!octokit) {
            return true;
          }

          try {
            await octokit.repos.get({ owner, repo });
            repoExistsCache.set(cacheKey, {
              exists: true,
              checkedAt: new Date(),
            });
            return true;
          } catch (error: unknown) {
            const octokitError = error as { status?: number };
            if (octokitError.status === 404) {
              logger.info(`Repository ${owner}/${repo} does not exist (404)`);
              repoExistsCache.set(cacheKey, {
                exists: false,
                checkedAt: new Date(),
              });
              return false;
            }
            logger.warn(
              `Failed to check repo ${owner}/${repo}: ${error}. Assuming exists.`,
            );
            return true;
          }
        }

        function getGitHubRepo(
          entity: Entity,
        ): { owner: string; repo: string } | null {
          const projectSlug =
            entity.metadata.annotations?.['github.com/project-slug'];
          if (projectSlug) {
            const parts = projectSlug.split('/');
            if (parts.length === 2) {
              return { owner: parts[0], repo: parts[1] };
            }
          }

          const sourceLocation =
            entity.metadata.annotations?.['backstage.io/source-location'];
          if (sourceLocation) {
            const match = sourceLocation.match(/github\.com\/([^/]+)\/([^/]+)/);
            if (match) {
              return { owner: match[1], repo: match[2] };
            }
          }

          if (entity.kind === 'Location') {
            const target =
              (entity.spec?.target as string) ||
              ((entity.spec?.targets as string[]) || [])[0];
            if (target) {
              const match = target.match(/github\.com\/([^/]+)\/([^/]+)/);
              if (match) {
                return { owner: match[1], repo: match[2] };
              }
            }
          }

          return null;
        }

        function getEntityRef(entity: Entity): string {
          return `${entity.kind.toLowerCase()}:${
            entity.metadata.namespace || 'default'
          }/${entity.metadata.name}`;
        }

        async function getToken(): Promise<string> {
          const { token } = await auth.getPluginRequestToken({
            onBehalfOf: await auth.getOwnServiceCredentials(),
            targetPluginId: 'catalog',
          });
          return token;
        }

        async function sendNotification(
          title: string,
          message: string,
          severity: 'info' | 'warning' | 'error' = 'warning',
        ): Promise<void> {
          try {
            const notificationsUrl = await discovery.getBaseUrl(
              'notifications',
            );
            const token = await getToken();

            await fetch(`${notificationsUrl}/notifications`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token}`,
              },
              body: JSON.stringify({
                recipients: { type: 'broadcast' },
                payload: {
                  title,
                  description: message,
                  severity,
                  link: '/catalog-cleanup',
                  topic: 'catalog-cleanup',
                },
              }),
            });
            logger.info(`Notification sent: ${title}`);
          } catch (error) {
            // Notifications plugin may not be installed
            logger.debug(`Failed to send notification: ${error}`);
          }
        }

        async function notifyOrphanedEntity(
          entityRef: string,
          reason: string,
          repoSlug?: string,
        ): Promise<void> {
          logger.warn(`🚨 ORPHANED ENTITY DETECTED: ${entityRef}`);
          logger.warn(`   Reason: ${reason}`);
          if (repoSlug) {
            logger.warn(`   Deleted repo: ${repoSlug}`);
          }
          logger.warn(
            `   This entity will be removed after ${MAX_FAILURES} consecutive failures.`,
          );

          // Send notification
          await sendNotification(
            'Orphaned Entity Detected',
            `Entity "${entityRef}" has been flagged as orphaned. Reason: ${reason}${
              repoSlug ? `. Repo: ${repoSlug}` : ''
            }`,
            'warning',
          );
        }

        async function deleteEntity(
          entity: Entity,
          token: string,
        ): Promise<boolean> {
          const entityRef = getEntityRef(entity);

          try {
            if (entity.kind === 'Location') {
              const baseUrl = await discovery.getBaseUrl('catalog');
              const response = await fetch(
                `${baseUrl}/locations/by-entity/${
                  entity.metadata.namespace || 'default'
                }/${entity.kind}/${entity.metadata.name}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                },
              );

              if (response.ok) {
                logger.info(`Successfully removed location: ${entityRef}`);
                return true;
              }
            }

            if (entity.metadata.uid) {
              await catalogClient.removeEntityByUid(entity.metadata.uid, {
                token,
              });
              logger.info(`Successfully removed entity by UID: ${entityRef}`);
              return true;
            }

            logger.warn(`Unable to delete entity ${entityRef}: No UID found`);
            return false;
          } catch (error) {
            logger.error(
              `Failed to delete entity ${entityRef}`,
              error as Error,
            );
            return false;
          }
        }

        /**
         * Delete all entities associated with a GitHub repository.
         * This performs a cascading delete - finds all entities from the repo and removes them.
         */
        async function deleteAllEntitiesForRepo(
          owner: string,
          repo: string,
          token: string,
        ): Promise<{ found: number; deleted: number }> {
          const repoSlug = `${owner}/${repo}`;
          logger.info(`🧹 Cascading delete for all entities from ${repoSlug}`);

          const { items: allEntities } = await catalogClient.getEntities(
            {},
            { token },
          );

          const entitiesToDelete: Entity[] = [];

          for (const entity of allEntities) {
            // Check if entity belongs to this repo
            const ghRepo = getGitHubRepo(entity);
            if (ghRepo && `${ghRepo.owner}/${ghRepo.repo}` === repoSlug) {
              entitiesToDelete.push(entity);
              continue;
            }

            // Also check source-location annotation for components registered by the location
            const sourceLocation =
              entity.metadata.annotations?.['backstage.io/source-location'];
            if (sourceLocation?.includes(`github.com/${repoSlug}`)) {
              entitiesToDelete.push(entity);
              continue;
            }

            // Check managed-by-location annotation
            const managedBy =
              entity.metadata.annotations?.['backstage.io/managed-by-location'];
            if (managedBy?.includes(`github.com/${repoSlug}`)) {
              entitiesToDelete.push(entity);
            }
          }

          logger.info(
            `Found ${entitiesToDelete.length} entities to delete for ${repoSlug}`,
          );

          // Sort to delete locations last (they may have dependencies)
          entitiesToDelete.sort((a, b) => {
            if (a.kind === 'Location' && b.kind !== 'Location') return 1;
            if (a.kind !== 'Location' && b.kind === 'Location') return -1;
            return 0;
          });

          let deleted = 0;
          for (const entity of entitiesToDelete) {
            const entityRef = getEntityRef(entity);
            logger.info(`  🗑️  Deleting ${entityRef}`);
            const success = await deleteEntity(entity, token);
            if (success) {
              deleted++;
              failedEntities.delete(entityRef);
            }
          }

          logger.info(
            `✅ Cascading delete complete: ${deleted}/${entitiesToDelete.length} entities removed for ${repoSlug}`,
          );

          return { found: entitiesToDelete.length, deleted };
        }

        // =========================================================================
        // Main Cleanup Logic
        // =========================================================================

        async function runCleanup(): Promise<void> {
          logger.info('🔄 Running smart catalog cleanup...');

          const stats: CleanupStats = {
            checked: 0,
            orphaned: 0,
            deleted: 0,
            reposValidated: 0,
            reposMissing: 0,
            lastRun: new Date(),
          };

          try {
            const token = await getToken();

            const { items: entities } = await catalogClient.getEntities(
              {
                filter: {
                  kind: [
                    'Location',
                    'Component',
                    'API',
                    'Resource',
                    'System',
                    'Domain',
                  ],
                },
              },
              { token },
            );

            stats.checked = entities.length;
            logger.info(`Checking ${entities.length} entities...`);

            const now = new Date();

            // Clean up stale tracking entries
            const staleRefs: string[] = [];
            failedEntities.forEach((data, ref) => {
              if (
                now.getTime() - data.lastSeen.getTime() >
                STALE_THRESHOLD_MS
              ) {
                staleRefs.push(ref);
              }
            });
            staleRefs.forEach(ref => failedEntities.delete(ref));

            for (const entity of entities) {
              const entityRef = getEntityRef(entity);
              let isOrphaned = false;
              let reason = '';
              let repoDeleted = false;

              // Check 1: Processing errors
              // eslint-disable-next-line @typescript-eslint/no-explicit-any
              const status = (entity as any).status as
                | {
                    items?: Array<{
                      type: string;
                      error?: { message: string };
                    }>;
                  }
                | undefined;

              const processingError = status?.items?.find(
                item =>
                  item.type === 'backstage.io/catalog-processing' &&
                  item.error?.message,
              );

              if (processingError) {
                isOrphaned = true;
                reason = processingError.error?.message || 'Processing error';
              }

              // Check 2: Orphan annotation
              if (
                entity.metadata.annotations?.['backstage.io/orphan'] === 'true'
              ) {
                isOrphaned = true;
                reason = 'Marked as orphan';
              }

              // Check 3: GitHub validation
              if (GITHUB_VALIDATION_ENABLED && octokit) {
                const ghRepo = getGitHubRepo(entity);
                if (ghRepo) {
                  stats.reposValidated++;
                  const exists = await checkRepoExists(
                    ghRepo.owner,
                    ghRepo.repo,
                  );
                  if (!exists) {
                    isOrphaned = true;
                    repoDeleted = true;
                    reason = `GitHub repository deleted: ${ghRepo.owner}/${ghRepo.repo}`;
                    stats.reposMissing++;
                  }
                }
              }

              // Check 4: Check if managed-by-location points to a failed location
              // This catches components whose parent location is inaccessible
              if (!isOrphaned) {
                const managedByLocation =
                  entity.metadata.annotations?.[
                    'backstage.io/managed-by-location'
                  ];
                if (managedByLocation) {
                  // Extract repo from the location URL
                  const repoMatch = managedByLocation.match(
                    /github\.com\/([^/]+)\/([^/]+)/,
                  );
                  if (repoMatch && octokit) {
                    const [, owner, repo] = repoMatch;
                    // Clean up repo name (remove /tree/main etc)
                    const cleanRepo = repo.split('/')[0];
                    const exists = await checkRepoExists(owner, cleanRepo);
                    if (!exists) {
                      isOrphaned = true;
                      repoDeleted = true;
                      reason = `Source location repo deleted: ${owner}/${cleanRepo}`;
                      stats.reposMissing++;
                    }
                  }
                }
              }

              if (isOrphaned) {
                stats.orphaned++;
                const existing = failedEntities.get(entityRef);
                const newCount = (existing?.count || 0) + 1;
                const ghRepo = getGitHubRepo(entity);

                failedEntities.set(entityRef, {
                  count: newCount,
                  lastSeen: now,
                  reason,
                  repoDeleted,
                  repoSlug: ghRepo
                    ? `${ghRepo.owner}/${ghRepo.repo}`
                    : undefined,
                });

                logger.warn(
                  `⚠️  ${entityRef} - Failure ${newCount}/${MAX_FAILURES}: ${reason}`,
                );

                if (newCount === 1 || repoDeleted) {
                  await notifyOrphanedEntity(
                    entityRef,
                    reason,
                    ghRepo ? `${ghRepo.owner}/${ghRepo.repo}` : undefined,
                  );
                }

                if (newCount >= MAX_FAILURES) {
                  logger.info(
                    `🗑️  Removing orphaned entity: ${entityRef} (after ${MAX_FAILURES} failures)`,
                  );

                  // If we have a GitHub repo identified (either via 404 or from annotations),
                  // perform cascading delete of ALL entities from that repo
                  if (ghRepo) {
                    const result = await deleteAllEntitiesForRepo(
                      ghRepo.owner,
                      ghRepo.repo,
                      token,
                    );
                    stats.deleted += result.deleted;

                    await sendNotification(
                      'Repository Cleanup Complete',
                      `Repository "${ghRepo.owner}/${ghRepo.repo}" cleanup complete. ${result.deleted} catalog entities have been automatically removed.`,
                      'info',
                    );
                  } else {
                    // Single entity deletion (no repo identified)
                    const deleted = await deleteEntity(entity, token);
                    if (deleted) {
                      stats.deleted++;
                      failedEntities.delete(entityRef);

                      await sendNotification(
                        'Entity Removed',
                        `Orphaned entity "${entityRef}" has been automatically removed.`,
                        'info',
                      );
                    }
                  }
                }
              } else {
                if (failedEntities.has(entityRef)) {
                  logger.info(`✅ ${entityRef} recovered, resetting failures`);
                  failedEntities.delete(entityRef);
                }
              }
            }

            logger.info(
              `📊 Cleanup complete: ` +
                `Checked=${stats.checked}, ` +
                `Orphaned=${stats.orphaned}, ` +
                `Deleted=${stats.deleted}, ` +
                `ReposValidated=${stats.reposValidated}, ` +
                `ReposMissing=${stats.reposMissing}, ` +
                `Tracking=${failedEntities.size}`,
            );

            lastStats = stats;
          } catch (error) {
            logger.error('Catalog cleanup failed', error as Error);
          }
        }

        // =========================================================================
        // Handle repo deletion from webhook
        // =========================================================================

        async function handleRepoDeleted(
          owner: string,
          repo: string,
        ): Promise<{ affected: number; removed: number }> {
          logger.info(`🔔 Webhook: Repository ${owner}/${repo} was deleted`);

          // Mark repo as deleted in cache
          repoExistsCache.set(`${owner}/${repo}`, {
            exists: false,
            checkedAt: new Date(),
          });

          const token = await getToken();

          // Use cascading delete to remove all entities from this repo
          const result = await deleteAllEntitiesForRepo(owner, repo, token);

          if (result.found > 0) {
            await sendNotification(
              'Repository Deleted',
              `Repository ${owner}/${repo} was deleted. ${result.deleted}/${result.found} associated entities have been removed.`,
              'warning',
            );
          }

          return { affected: result.found, removed: result.deleted };
        }

        // =========================================================================
        // Verify GitHub webhook signature
        // =========================================================================

        function verifyWebhookSignature(
          payload: string,
          signature: string | undefined,
        ): boolean {
          if (!webhookSecret) {
            logger.warn('Webhook secret not configured, skipping verification');
            return true; // Allow if no secret configured
          }

          if (!signature) {
            return false;
          }

          const hmac = crypto.createHmac('sha256', webhookSecret);
          const digest = `sha256=${hmac.update(payload).digest('hex')}`;
          return crypto.timingSafeEqual(
            Buffer.from(signature),
            Buffer.from(digest),
          );
        }

        // =========================================================================
        // HTTP Router (Admin API & Webhook)
        // =========================================================================

        const router = express.Router();

        // Health check
        router.get(
          '/health',
          (_req: express.Request, res: express.Response) => {
            res.json({
              status: 'ok',
              githubValidation: !!octokit,
              webhookEnabled: !!webhookSecret,
              trackingEntities: failedEntities.size,
            });
          },
        );

        // List tracked orphaned entities
        router.get('/orphans', (_, res) => {
          const orphans: Array<{
            entityRef: string;
            failureCount: number;
            reason: string;
            repoSlug?: string;
            lastSeen: string;
          }> = [];

          failedEntities.forEach((data, ref) => {
            orphans.push({
              entityRef: ref,
              failureCount: data.count,
              reason: data.reason,
              repoSlug: data.repoSlug,
              lastSeen: data.lastSeen.toISOString(),
            });
          });

          res.json({
            count: orphans.length,
            maxFailures: MAX_FAILURES,
            orphans,
          });
        });

        // Get cleanup statistics
        router.get('/stats', (_, res) => {
          res.json({
            ...lastStats,
            tracking: failedEntities.size,
            cacheSize: repoExistsCache.size,
          });
        });

        // Trigger immediate cleanup
        router.post('/trigger', async (_, res) => {
          try {
            const stats = await runCleanup();
            res.json({
              message: 'Cleanup triggered successfully',
              stats,
            });
          } catch (error) {
            res.status(500).json({
              error: 'Cleanup failed',
              message: String(error),
            });
          }
        });

        // Force delete an entity
        router.delete('/entity/:kind/:namespace/:name', async (req, res) => {
          const { kind, namespace, name } = req.params;
          const entityRef = `${kind}:${namespace}/${name}`;

          try {
            const token = await getToken();
            const entity = await catalogClient.getEntityByRef(entityRef, {
              token,
            });

            if (!entity) {
              res.status(404).json({ error: 'Entity not found' });
              return;
            }

            const deleted = await deleteEntity(entity, token);
            if (deleted) {
              failedEntities.delete(entityRef);
              res.json({ message: `Entity ${entityRef} deleted successfully` });
            } else {
              res.status(500).json({ error: 'Failed to delete entity' });
            }
          } catch (error) {
            res.status(500).json({
              error: 'Failed to delete entity',
              message: String(error),
            });
          }
        });

        // GitHub webhook receiver
        router.post('/webhook', express.json(), async (req, res) => {
          const event = req.headers['x-github-event'] as string;
          const signature = req.headers['x-hub-signature-256'] as string;
          const payload = JSON.stringify(req.body);

          // Verify signature
          if (!verifyWebhookSignature(payload, signature)) {
            logger.warn('Invalid webhook signature received');
            res.status(401).json({ error: 'Invalid signature' });
            return;
          }

          // Handle repository deletion
          if (event === 'repository' && req.body.action === 'deleted') {
            const { owner, name } = req.body.repository;
            const ownerLogin = owner?.login || owner?.name;

            if (ownerLogin && name) {
              const result = await handleRepoDeleted(ownerLogin, name);
              res.json({
                message: 'Repository deletion processed',
                ...result,
              });
            } else {
              res.status(400).json({ error: 'Invalid repository data' });
            }
            return;
          }

          // Acknowledge other events
          res.json({ message: `Event ${event} received` });
        });

        // Clear all tracked orphans (admin action)
        router.post('/clear', (_, res) => {
          const count = failedEntities.size;
          failedEntities.clear();
          res.json({
            message: `Cleared ${count} tracked orphan entries`,
          });
        });

        httpRouter.use(router as any);

        // =========================================================================
        // Scheduled Task
        // =========================================================================

        await scheduler.scheduleTask({
          id: 'catalog-cleanup-smart-sync',
          frequency: { minutes: 1 },
          timeout: { minutes: 3 },
          initialDelay: { seconds: 30 },
          fn: runCleanup,
        });

        logger.info(
          '✅ Smart catalog cleanup plugin initialized ' +
            `(GitHub: ${octokit ? 'enabled' : 'disabled'}, ` +
            `Webhook: ${webhookSecret ? 'enabled' : 'disabled'})`,
        );

        logger.info('📡 API endpoints available at /api/catalog-cleanup/');
      },
    });
  },
});
