import {
  coreServices,
  createBackendPlugin,
  type HttpAuthService,
} from '@backstage/backend-plugin-api';
import { CatalogClient } from '@backstage/catalog-client';
import { Octokit } from '@octokit/rest';
import { Entity } from '@backstage/catalog-model';
import * as express from 'express';
import * as crypto from 'crypto';
import rateLimit from 'express-rate-limit';
import { ACCOUNT_ANNOTATION, directory } from './accounts/directory';

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
 * API ENDPOINTS (portal administrators only, except the webhook, which is
 * signed by GitHub and refused when no secret is configured; an
 * administrator sees, counts and removes only shared entities and those of
 * their own accounts):
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
  // The account the entity belongs to; none for a shared entity
  account?: string;
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
// What the last run counted, per account; shared entities under undefined
let lastStats = new Map<string | undefined, CleanupStats>();
let lastRun: Date | undefined;

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
        httpAuth: coreServices.httpAuth,
        userInfo: coreServices.userInfo,
      },
      async init({
        logger,
        scheduler,
        discovery,
        auth,
        config,
        httpRouter,
        httpAuth,
        userInfo,
      }) {
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

        // Who is told about entities of `accounts` (undefined for a shared
        // entity): the portal administrators who may see every one of
        // them, and the person themselves for a personal account.
        async function recipientsFor(
          accounts: Array<string | undefined>,
        ): Promise<string[]> {
          const owned = [
            ...new Set(
              accounts.filter(
                (account): account is string => account !== undefined,
              ),
            ),
          ];
          const candidates = new Set(await directory.portalAdmins());
          if (owned.length === 0) {
            return [...candidates];
          }
          if (owned.length === 1 && owned[0].startsWith('user:')) {
            candidates.add(owned[0]);
          }
          const recipients: string[] = [];
          for (const candidate of candidates) {
            // Who is in an administrators' group is not known here
            if (!candidate.startsWith('user:')) {
              continue;
            }
            const seen = await directory.accountsOf(candidate);
            if (owned.every(account => seen.includes(account))) {
              recipients.push(candidate);
            }
          }
          return recipients;
        }

        async function sendNotification(
          title: string,
          message: string,
          severity: 'info' | 'warning' | 'error',
          accounts: Array<string | undefined>,
        ): Promise<void> {
          try {
            const recipients = await recipientsFor(accounts);
            if (recipients.length === 0) {
              return;
            }
            const notificationsUrl = await discovery.getBaseUrl(
              'notifications',
            );
            const { token } = await auth.getPluginRequestToken({
              onBehalfOf: await auth.getOwnServiceCredentials(),
              targetPluginId: 'notifications',
            });

            await fetch(`${notificationsUrl}/notifications`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${token}`,
              },
              body: JSON.stringify({
                recipients: { type: 'entity', entityRef: recipients },
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
          account: string | undefined,
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
            [account],
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
         *
         * `only` keeps it to the entities of one account (shared ones for
         * undefined): what one entity sets off never removes another
         * account's entities, whatever repository they say they are from.
         */
        async function deleteAllEntitiesForRepo(
          owner: string,
          repo: string,
          token: string,
          only?: { account: string | undefined },
        ): Promise<{
          found: number;
          deleted: number;
          accounts: Array<string | undefined>;
        }> {
          const repoSlug = `${owner}/${repo}`;
          logger.info(`🧹 Cascading delete for all entities from ${repoSlug}`);

          const { items: allEntities } = await catalogClient.getEntities(
            {},
            { token },
          );

          const entitiesToDelete: Entity[] = [];

          for (const entity of allEntities) {
            if (
              only &&
              entity.metadata.annotations?.[ACCOUNT_ANNOTATION] !== only.account
            ) {
              continue;
            }
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

          return {
            found: entitiesToDelete.length,
            deleted,
            accounts: entitiesToDelete.map(
              entity => entity.metadata.annotations?.[ACCOUNT_ANNOTATION],
            ),
          };
        }

        // =========================================================================
        // Main Cleanup Logic
        // =========================================================================

        async function runCleanup(): Promise<void> {
          logger.info('🔄 Running smart catalog cleanup...');

          const perAccount = new Map<string | undefined, CleanupStats>();
          const statsOf = (account: string | undefined) => {
            let counted = perAccount.get(account);
            if (!counted) {
              counted = {
                checked: 0,
                orphaned: 0,
                deleted: 0,
                reposValidated: 0,
                reposMissing: 0,
              };
              perAccount.set(account, counted);
            }
            return counted;
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
              const account = entity.metadata.annotations?.[ACCOUNT_ANNOTATION];
              const stats = statsOf(account);
              stats.checked++;
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

              // Check 2: Orphan annotation. Only the catalog sets it: the
              // accounts processor removes it from what a registered file
              // says (accounts/catalogModule.ts).
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
                  account,
                });

                logger.warn(
                  `⚠️  ${entityRef} - Failure ${newCount}/${MAX_FAILURES}: ${reason}`,
                );

                if (newCount === 1 || repoDeleted) {
                  await notifyOrphanedEntity(
                    entityRef,
                    reason,
                    account,
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
                      { account },
                    );
                    stats.deleted += result.deleted;

                    await sendNotification(
                      'Repository Cleanup Complete',
                      `Repository "${ghRepo.owner}/${ghRepo.repo}" cleanup complete. ${result.deleted} catalog entities have been automatically removed.`,
                      'info',
                      result.accounts,
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
                        [account],
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

            const total = (count: (stats: CleanupStats) => number) =>
              [...perAccount.values()].reduce(
                (sum, stats) => sum + count(stats),
                0,
              );
            logger.info(
              `📊 Cleanup complete: ` +
                `Checked=${total(stats => stats.checked)}, ` +
                `Orphaned=${total(stats => stats.orphaned)}, ` +
                `Deleted=${total(stats => stats.deleted)}, ` +
                `ReposValidated=${total(stats => stats.reposValidated)}, ` +
                `ReposMissing=${total(stats => stats.reposMissing)}, ` +
                `Tracking=${failedEntities.size}`,
            );

            lastStats = perAccount;
            lastRun = new Date();
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

          // GitHub says the repository is gone, so this is for every
          // account that has entities from it.
          const result = await deleteAllEntitiesForRepo(owner, repo, token);

          if (result.found > 0) {
            await sendNotification(
              'Repository Deleted',
              `Repository ${owner}/${repo} was deleted. ${result.deleted}/${result.found} associated entities have been removed.`,
              'warning',
              result.accounts,
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
          // Without a secret nothing shows that GitHub sent it.
          if (!webhookSecret) {
            logger.warn('Webhook secret not configured, refusing the webhook');
            return false;
          }

          if (!signature) {
            return false;
          }

          const hmac = crypto.createHmac('sha256', webhookSecret);
          const digest = Buffer.from(
            `sha256=${hmac.update(payload).digest('hex')}`,
          );
          const given = Buffer.from(signature);
          return (
            given.length === digest.length &&
            crypto.timingSafeEqual(given, digest)
          );
        }

        // =========================================================================
        // HTTP Router (Admin API & Webhook)
        // =========================================================================

        const router = express.Router();

        // Every route but the webhook, which GitHub signs, is for portal
        // administrators, within their own accounts.
        router.use(async (req, res, next) => {
          if (req.path === '/webhook') {
            next();
            return;
          }
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
                error:
                  'Only a portal administrator can manage catalog clean-up',
              });
              return;
            }
            res.locals.accounts = await directory.accountsOf(
              caller.userEntityRef,
            );
            next();
          } catch (error) {
            logger.error('Failed to check the caller', error as Error);
            res.status(500).json({ error: 'Failed to check the caller' });
          }
        });

        // Whether something of `account` is shared, or of the caller's accounts
        const isWithin = (res: express.Response, account?: string) =>
          account === undefined ||
          (res.locals.accounts as string[]).includes(account);

        // The tracked entities the caller may see
        const trackedFor = (res: express.Response) =>
          [...failedEntities].filter(([, data]) => isWithin(res, data.account));

        // Health check
        router.get(
          '/health',
          (_req: express.Request, res: express.Response) => {
            res.json({
              status: 'ok',
              githubValidation: !!octokit,
              webhookEnabled: !!webhookSecret,
              trackingEntities: trackedFor(res).length,
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

          trackedFor(res).forEach(([ref, data]) => {
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

        // What the last run counted of what the caller may see
        const statsFor = (res: express.Response) => {
          const stats = {
            checked: 0,
            orphaned: 0,
            deleted: 0,
            reposValidated: 0,
            reposMissing: 0,
          };
          for (const [account, counted] of lastStats) {
            if (isWithin(res, account)) {
              stats.checked += counted.checked;
              stats.orphaned += counted.orphaned;
              stats.deleted += counted.deleted;
              stats.reposValidated += counted.reposValidated;
              stats.reposMissing += counted.reposMissing;
            }
          }
          return { ...stats, lastRun, tracking: trackedFor(res).length };
        };

        // Get cleanup statistics
        router.get('/stats', (_, res) => {
          res.json(statsFor(res));
        });

        // Trigger immediate cleanup
        // Rate limiters for admin and webhook endpoints
        const adminLimiter = rateLimit({
          windowMs: 60 * 1000, // 1 minute
          max: 30, // limit each IP to 30 requests per window
          standardHeaders: true,
          legacyHeaders: false,
        });

        const webhookLimiter = rateLimit({
          windowMs: 60 * 1000, // 1 minute
          max: 60, // limit each IP to 60 webhook requests per window
          standardHeaders: true,
          legacyHeaders: false,
        });

        router.post('/trigger', adminLimiter, async (_, res) => {
          try {
            await runCleanup();
            res.json({
              message: 'Cleanup triggered successfully',
              stats: statsFor(res),
            });
          } catch (error) {
            res.status(500).json({
              error: 'Cleanup failed',
              message: String(error),
            });
          }
        });

        // Force delete an entity
        router.delete(
          '/entity/:kind/:namespace/:name',
          adminLimiter,
          async (req, res) => {
            const { kind, namespace, name } = req.params;
            const entityRef = `${kind}:${namespace}/${name}`;

            try {
              const token = await getToken();
              const entity = await catalogClient.getEntityByRef(entityRef, {
                token,
              });

              // An entity of another account answers as one that is not there
              if (
                !entity ||
                !isWithin(
                  res,
                  entity.metadata.annotations?.[ACCOUNT_ANNOTATION],
                )
              ) {
                res.status(404).json({ error: 'Entity not found' });
                return;
              }

              const deleted = await deleteEntity(entity, token);
              if (deleted) {
                failedEntities.delete(entityRef);
                res.json({
                  message: `Entity ${entityRef} deleted successfully`,
                });
              } else {
                res.status(500).json({ error: 'Failed to delete entity' });
              }
            } catch (error) {
              res.status(500).json({
                error: 'Failed to delete entity',
                message: String(error),
              });
            }
          },
        );

        // GitHub webhook receiver
        router.post(
          '/webhook',
          webhookLimiter,
          express.json(),
          async (req, res) => {
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
          },
        );

        // Clear all tracked orphans (admin action)
        router.post('/clear', adminLimiter, (_, res) => {
          const tracked = trackedFor(res);
          const count = tracked.length;
          tracked.forEach(([ref]) => failedEntities.delete(ref));
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
