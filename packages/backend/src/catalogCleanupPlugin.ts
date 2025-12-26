import {
  coreServices,
  createBackendPlugin,
} from '@backstage/backend-plugin-api';
import { CatalogClient } from '@backstage/catalog-client';
import { Octokit } from '@octokit/rest';
import { Entity } from '@backstage/catalog-model';

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
 * - Graceful degradation when GitHub API is unavailable
 *
 * DETECTION METHODS:
 * 1. Processing errors in entity status (backstage.io/catalog-processing)
 * 2. Orphan annotation (backstage.io/orphan)
 * 3. Direct GitHub API validation for repos with github.com/project-slug
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
}

interface CleanupStats {
  checked: number;
  orphaned: number;
  deleted: number;
  reposValidated: number;
  reposMissing: number;
}

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
      },
      async init({ logger, scheduler, discovery, auth, config }) {
        const catalogClient = new CatalogClient({
          discoveryApi: discovery,
        });

        // Configuration
        const MAX_FAILURES = 3; // Delete after 3 consecutive failures
        const STALE_THRESHOLD_MS = 30 * 60 * 1000; // 30 minutes
        const GITHUB_VALIDATION_ENABLED = true; // Enable proactive GitHub checks

        // Track failed entities across runs (in-memory)
        const failedEntities = new Map<string, FailedEntity>();

        // GitHub token for repository validation
        const githubToken =
          config.getOptionalString('integrations.github.0.token') ||
          process.env.GITHUB_TOKEN;

        const octokit = githubToken ? new Octokit({ auth: githubToken }) : null;

        if (!octokit) {
          logger.warn(
            'GitHub token not configured. Repository validation will be disabled.',
          );
        }

        // Cache for GitHub repo existence checks (avoid rate limiting)
        const repoExistsCache = new Map<
          string,
          { exists: boolean; checkedAt: Date }
        >();
        const REPO_CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes

        /**
         * Check if a GitHub repository exists
         */
        async function checkRepoExists(
          owner: string,
          repo: string,
        ): Promise<boolean> {
          const cacheKey = `${owner}/${repo}`;
          const cached = repoExistsCache.get(cacheKey);

          // Return cached result if fresh
          if (
            cached &&
            Date.now() - cached.checkedAt.getTime() < REPO_CACHE_TTL_MS
          ) {
            return cached.exists;
          }

          if (!octokit) {
            return true; // Assume exists if we can't check
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
            // For other errors (rate limiting, network), assume repo exists
            logger.warn(
              `Failed to check repo ${owner}/${repo}: ${error}. Assuming exists.`,
            );
            return true;
          }
        }

        /**
         * Extract GitHub owner/repo from entity annotations
         */
        function getGitHubRepo(
          entity: Entity,
        ): { owner: string; repo: string } | null {
          // Try github.com/project-slug annotation
          const projectSlug =
            entity.metadata.annotations?.['github.com/project-slug'];
          if (projectSlug) {
            const parts = projectSlug.split('/');
            if (parts.length === 2) {
              return { owner: parts[0], repo: parts[1] };
            }
          }

          // Try backstage.io/source-location annotation
          const sourceLocation =
            entity.metadata.annotations?.['backstage.io/source-location'];
          if (sourceLocation) {
            const match = sourceLocation.match(/github\.com\/([^/]+)\/([^/]+)/);
            if (match) {
              return { owner: match[1], repo: match[2] };
            }
          }

          // Try spec.target for Location entities
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

        /**
         * Get entity reference string
         */
        function getEntityRef(entity: Entity): string {
          return `${entity.kind.toLowerCase()}:${
            entity.metadata.namespace || 'default'
          }/${entity.metadata.name}`;
        }

        /**
         * Send notification for orphaned entity (placeholder - integrate with notifications plugin)
         */
        async function notifyOrphanedEntity(
          entityRef: string,
          reason: string,
          repoSlug?: string,
        ): Promise<void> {
          // TODO: Integrate with @backstage/plugin-notifications-backend
          // For now, just log prominently
          logger.warn(`🚨 ORPHANED ENTITY DETECTED: ${entityRef}`);
          logger.warn(`   Reason: ${reason}`);
          if (repoSlug) {
            logger.warn(`   Deleted repo: ${repoSlug}`);
          }
          logger.warn(
            `   This entity will be removed after ${MAX_FAILURES} consecutive failures.`,
          );
        }

        /**
         * Delete an entity from the catalog
         */
        async function deleteEntity(
          entity: Entity,
          token: string,
        ): Promise<boolean> {
          const entityRef = getEntityRef(entity);

          try {
            // First try to delete by location (for Location entities)
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

            // Fall back to deleting by UID
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

        // =========================================================================
        // Main cleanup task
        // =========================================================================
        await scheduler.scheduleTask({
          id: 'catalog-cleanup-smart-sync',
          frequency: { minutes: 5 },
          timeout: { minutes: 5 },
          initialDelay: { minutes: 1 },
          fn: async () => {
            logger.info('🔄 Running smart catalog cleanup...');

            const stats: CleanupStats = {
              checked: 0,
              orphaned: 0,
              deleted: 0,
              reposValidated: 0,
              reposMissing: 0,
            };

            try {
              // Get service token for catalog API calls
              const { token } = await auth.getPluginRequestToken({
                onBehalfOf: await auth.getOwnServiceCredentials(),
                targetPluginId: 'catalog',
              });

              // Fetch all entities (not just Locations)
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

                // Check 1: Processing errors in status
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
                  entity.metadata.annotations?.['backstage.io/orphan'] ===
                  'true'
                ) {
                  isOrphaned = true;
                  reason = 'Marked as orphan';
                }

                // Check 3: GitHub repository validation (proactive)
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

                if (isOrphaned) {
                  stats.orphaned++;
                  const existing = failedEntities.get(entityRef);
                  const newCount = (existing?.count || 0) + 1;

                  failedEntities.set(entityRef, {
                    count: newCount,
                    lastSeen: now,
                    reason,
                    repoDeleted,
                  });

                  logger.warn(
                    `⚠️  ${entityRef} - Failure ${newCount}/${MAX_FAILURES}: ${reason}`,
                  );

                  // Notify on first detection or when repo is deleted
                  if (newCount === 1 || repoDeleted) {
                    const ghRepo = getGitHubRepo(entity);
                    await notifyOrphanedEntity(
                      entityRef,
                      reason,
                      ghRepo ? `${ghRepo.owner}/${ghRepo.repo}` : undefined,
                    );
                  }

                  // Delete after MAX_FAILURES
                  if (newCount >= MAX_FAILURES) {
                    logger.info(
                      `🗑️  Removing orphaned entity: ${entityRef} (after ${MAX_FAILURES} failures)`,
                    );

                    const deleted = await deleteEntity(entity, token);
                    if (deleted) {
                      stats.deleted++;
                      failedEntities.delete(entityRef);
                    }
                  }
                } else {
                  // Entity is healthy, reset failure count
                  if (failedEntities.has(entityRef)) {
                    logger.info(
                      `✅ ${entityRef} recovered, resetting failures`,
                    );
                    failedEntities.delete(entityRef);
                  }
                }
              }

              // Log summary
              logger.info(
                `📊 Cleanup complete: ` +
                  `Checked=${stats.checked}, ` +
                  `Orphaned=${stats.orphaned}, ` +
                  `Deleted=${stats.deleted}, ` +
                  `ReposValidated=${stats.reposValidated}, ` +
                  `ReposMissing=${stats.reposMissing}, ` +
                  `Tracking=${failedEntities.size}`,
              );
            } catch (error) {
              logger.error('Catalog cleanup failed', error as Error);
            }
          },
        });

        // =========================================================================
        // GitHub webhook handler for repository deletion events (optional)
        // =========================================================================
        // TODO: Add HTTP endpoint to receive GitHub webhooks for repo deletion
        // This would provide instant detection instead of polling

        logger.info(
          '✅ Smart catalog cleanup plugin initialized ' +
            `(GitHub validation: ${octokit ? 'enabled' : 'disabled'})`,
        );
      },
    });
  },
});
