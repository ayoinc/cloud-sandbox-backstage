import {
  coreServices,
  createBackendPlugin,
} from '@backstage/backend-plugin-api';
import {
  CatalogClient,
  CATALOG_FILTER_EXISTS,
} from '@backstage/catalog-client';

/**
 * TechDocs Build Queue Plugin
 *
 * Proactively builds TechDocs for all entities with techdocs-ref annotation.
 * Uses a queue-based approach with retry logic:
 * - Discovers all entities with TechDocs configuration
 * - Queues them for building
 * - Retries failed builds up to 2 times (moved to back of queue)
 * - Reports errors after max retries exceeded
 *
 * This ensures all docs are pre-built rather than waiting for on-demand generation.
 */

interface QueueItem {
  entityRef: string;
  namespace: string;
  kind: string;
  name: string;
  retryCount: number;
  lastError?: string;
  addedAt: Date;
}

interface BuildResult {
  success: boolean;
  error?: string;
}

export default createBackendPlugin({
  pluginId: 'techdocs-queue',
  register(env) {
    env.registerInit({
      deps: {
        logger: coreServices.logger,
        scheduler: coreServices.scheduler,
        discovery: coreServices.discovery,
        auth: coreServices.auth,
      },
      async init({ logger, scheduler, discovery, auth }) {
        const catalogClient = new CatalogClient({
          discoveryApi: discovery,
        });

        // Build queue with retry support
        const buildQueue: QueueItem[] = [];
        const MAX_RETRIES = 2;
        const CONCURRENT_BUILDS = 6; // Increased from 3 for faster processing
        const BUILD_DELAY_MS = 1000; // Reduced delay for faster throughput

        // Track successfully built entities to avoid rebuilding
        const builtEntities = new Set<string>();
        // Track permanently failed entities
        const failedEntities = new Map<string, string>();

        /**
         * Trigger a TechDocs sync/build for an entity
         */
        async function triggerBuild(
          item: QueueItem,
          token: string,
        ): Promise<BuildResult> {
          try {
            const techdocsBaseUrl = await discovery.getBaseUrl('techdocs');
            const syncUrl = `${techdocsBaseUrl}/sync/${item.namespace}/${item.kind}/${item.name}`;

            logger.debug(`Triggering TechDocs build for ${item.entityRef}`);

            const response = await fetch(syncUrl, {
              method: 'GET',
              headers: {
                Authorization: `Bearer ${token}`,
              },
            });

            if (response.ok) {
              return { success: true };
            }

            const errorText = await response.text();
            return {
              success: false,
              error: `HTTP ${response.status}: ${errorText.substring(0, 200)}`,
            };
          } catch (error) {
            return {
              success: false,
              error: error instanceof Error ? error.message : String(error),
            };
          }
        }

        /**
         * Process items in the queue with concurrency control
         */
        async function processQueue(token: string): Promise<void> {
          if (buildQueue.length === 0) {
            return;
          }

          logger.info(
            `Processing TechDocs build queue: ${buildQueue.length} items pending`,
          );

          // Process in batches
          const batch: QueueItem[] = [];
          while (batch.length < CONCURRENT_BUILDS && buildQueue.length > 0) {
            const item = buildQueue.shift();
            if (item) {
              batch.push(item);
            }
          }

          // Build concurrently
          const results = await Promise.allSettled(
            batch.map(async item => {
              const result = await triggerBuild(item, token);

              // Add delay between builds
              await new Promise(resolve => setTimeout(resolve, BUILD_DELAY_MS));

              return { item, result };
            }),
          );

          // Process results
          for (const settledResult of results) {
            if (settledResult.status === 'rejected') {
              continue;
            }

            const { item, result } = settledResult.value;

            if (result.success) {
              logger.info(`Successfully built TechDocs for ${item.entityRef}`);
              builtEntities.add(item.entityRef);
              failedEntities.delete(item.entityRef);
            } else {
              item.retryCount++;
              item.lastError = result.error;

              if (item.retryCount <= MAX_RETRIES) {
                // Move to back of queue for retry
                logger.warn(
                  `TechDocs build failed for ${item.entityRef} (attempt ${
                    item.retryCount
                  }/${MAX_RETRIES + 1}): ${result.error}`,
                );
                buildQueue.push(item);
              } else {
                // Max retries exceeded - report error
                logger.error(
                  `TechDocs build permanently failed for ${
                    item.entityRef
                  } after ${MAX_RETRIES + 1} attempts: ${result.error}`,
                );
                failedEntities.set(
                  item.entityRef,
                  result.error || 'Unknown error',
                );
              }
            }
          }
        }

        /**
         * Discover entities with TechDocs and add to queue
         */
        async function discoverAndQueueEntities(token: string): Promise<void> {
          try {
            // Fetch all entities with techdocs-ref annotation
            // Note: The catalog filter checks for presence of the annotation key, not a wildcard value
            const { items: entities } = await catalogClient.getEntities(
              {
                filter: {
                  'metadata.annotations.backstage.io/techdocs-ref':
                    CATALOG_FILTER_EXISTS,
                },
                fields: [
                  'metadata.name',
                  'metadata.namespace',
                  'kind',
                  'metadata.annotations',
                ],
              },
              { token },
            );

            logger.info(
              `Found ${entities.length} entities with TechDocs configuration`,
            );

            let newItems = 0;
            for (const entity of entities) {
              const entityRef = `${entity.kind.toLowerCase()}:${
                entity.metadata.namespace || 'default'
              }/${entity.metadata.name}`;

              // Skip if already built or in queue
              if (builtEntities.has(entityRef)) {
                continue;
              }

              // Skip if permanently failed (will retry on next full scan)
              if (failedEntities.has(entityRef)) {
                continue;
              }

              // Skip if already in queue
              if (buildQueue.some(item => item.entityRef === entityRef)) {
                continue;
              }

              // Add to queue
              buildQueue.push({
                entityRef,
                namespace: entity.metadata.namespace || 'default',
                kind: entity.kind.toLowerCase(),
                name: entity.metadata.name,
                retryCount: 0,
                addedAt: new Date(),
              });
              newItems++;
            }

            if (newItems > 0) {
              logger.info(
                `Added ${newItems} new entities to TechDocs build queue`,
              );
            }
          } catch (error) {
            logger.error(
              'Failed to discover TechDocs entities',
              error as Error,
            );
          }
        }

        // Schedule entity discovery (runs every 10 minutes)
        await scheduler.scheduleTask({
          id: 'techdocs-queue-discovery',
          frequency: { minutes: 10 },
          timeout: { minutes: 5 },
          initialDelay: { seconds: 30 },
          fn: async () => {
            logger.info('Running TechDocs entity discovery');

            const { token } = await auth.getPluginRequestToken({
              onBehalfOf: await auth.getOwnServiceCredentials(),
              targetPluginId: 'catalog',
            });

            await discoverAndQueueEntities(token);
          },
        });

        // Schedule queue processing (runs every 2 minutes)
        await scheduler.scheduleTask({
          id: 'techdocs-queue-processor',
          frequency: { minutes: 2 },
          timeout: { minutes: 10 },
          initialDelay: { minutes: 1 },
          fn: async () => {
            if (buildQueue.length === 0) {
              return;
            }

            const { token } = await auth.getPluginRequestToken({
              onBehalfOf: await auth.getOwnServiceCredentials(),
              targetPluginId: 'techdocs',
            });

            await processQueue(token);

            // Log summary
            logger.info(
              `TechDocs queue status: ${buildQueue.length} pending, ${builtEntities.size} built, ${failedEntities.size} failed`,
            );

            // Log failed entities periodically
            if (failedEntities.size > 0) {
              const failedList = Array.from(failedEntities.entries())
                .map(([ref, err]) => `${ref}: ${err.substring(0, 100)}`)
                .join('\n  ');
              logger.warn(
                `Permanently failed TechDocs builds:\n  ${failedList}`,
              );
            }
          },
        });

        // Schedule periodic reset of failed entities (runs daily)
        await scheduler.scheduleTask({
          id: 'techdocs-queue-reset-failed',
          frequency: { hours: 24 },
          timeout: { minutes: 1 },
          initialDelay: { hours: 1 },
          fn: async () => {
            if (failedEntities.size > 0) {
              logger.info(
                `Resetting ${failedEntities.size} failed TechDocs entities for retry`,
              );
              failedEntities.clear();
            }
          },
        });

        logger.info('TechDocs Build Queue plugin initialized');
        logger.info(
          `Configuration: max retries=${MAX_RETRIES}, concurrent builds=${CONCURRENT_BUILDS}`,
        );
      },
    });
  },
});
