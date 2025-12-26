import {
  createBackendPlugin,
  coreServices,
} from '@backstage/backend-plugin-api';
import { catalogServiceRef } from '@backstage/plugin-catalog-node/alpha';
import { Octokit } from '@octokit/rest';
import { Knex } from 'knex';

/**
 * =============================================================================
 * GitHub Team Sync Backend Plugin
 * =============================================================================
 *
 * Provides bi-directional synchronization between Backstage Groups and GitHub Teams.
 *
 * SYNC BEHAVIOR:
 * - Only syncs groups with annotation: github.com/sync: "true"
 * - Creates GitHub teams when Backstage groups are created
 * - Deletes GitHub teams when Backstage groups are deleted (if synced)
 * - Syncs team membership bi-directionally
 * - Persists sync state to database (survives restarts)
 *
 * ROLE MAPPING:
 * - Groups can have a backstage.io/role annotation (admins, editors, viewers)
 * - When users are added to GitHub teams, they inherit the team's role
 * - Role hierarchy: admins > editors > viewers
 *
 * ANNOTATIONS:
 * - github.com/sync: "true" - Enable sync for this group
 * - github.com/team-slug: "team-name" - Set by GitHub org provider (do not sync)
 * - backstage.io/role: "editors" - Map team members to a permission role
 *
 * Configuration:
 * - GITHUB_TOKEN: Token with admin:org scope for team management
 * - GITHUB_ORG: The GitHub organization to sync with
 *
 * =============================================================================
 */

interface BackstageGroup {
  name: string;
  description?: string;
  members: string[];
  role?: string;
  shouldSync: boolean;
}

interface GitHubTeam {
  id: number;
  slug: string;
  name: string;
}

// Database table for sync state
const SYNC_STATE_TABLE = 'github_team_sync_state';

export const githubTeamSyncPlugin = createBackendPlugin({
  pluginId: 'github-team-sync',
  register(env) {
    env.registerInit({
      deps: {
        logger: coreServices.logger,
        config: coreServices.rootConfig,
        scheduler: coreServices.scheduler,
        catalog: catalogServiceRef,
        database: coreServices.database,
      },
      async init({ logger, config, scheduler, catalog, database }) {
        // Get GitHub token from integrations config or environment
        let githubToken: string | undefined;
        try {
          const githubConfigs = config.getOptionalConfigArray(
            'integrations.github',
          );
          if (githubConfigs && githubConfigs.length > 0) {
            githubToken = githubConfigs[0].getOptionalString('token');
          }
        } catch {
          // Fall back to environment variable
        }
        githubToken = githubToken || process.env.GITHUB_TOKEN;

        const githubOrg = process.env.GITHUB_ORG;

        if (!githubToken) {
          logger.warn('GitHub token not configured - team sync disabled');
          return;
        }

        if (!githubOrg) {
          logger.warn('GITHUB_ORG not configured - team sync disabled');
          return;
        }

        logger.info(`Initializing GitHub Team Sync for org: ${githubOrg}`);

        const octokit = new Octokit({ auth: githubToken });

        // Get database client
        const db = await database.getClient();

        // Initialize database table for sync state
        async function initDatabase(knex: Knex): Promise<void> {
          const hasTable = await knex.schema.hasTable(SYNC_STATE_TABLE);
          if (!hasTable) {
            logger.info(`Creating ${SYNC_STATE_TABLE} table`);
            await knex.schema.createTable(SYNC_STATE_TABLE, table => {
              table.string('team_slug').primary();
              table.string('source').notNullable(); // 'backstage' or 'github'
              table.timestamp('created_at').defaultTo(knex.fn.now());
              table.timestamp('updated_at').defaultTo(knex.fn.now());
            });
            logger.info(`Created ${SYNC_STATE_TABLE} table`);
          }
        }

        // Helper: Get synced teams from database
        async function getSyncedTeams(): Promise<Set<string>> {
          const rows = await db(SYNC_STATE_TABLE)
            .where('source', 'backstage')
            .select('team_slug');
          return new Set(
            rows.map((r: { team_slug: string }) => r.team_slug.toLowerCase()),
          );
        }

        // Helper: Add team to sync state
        async function addSyncedTeam(teamSlug: string): Promise<void> {
          const slug = teamSlug.toLowerCase();
          const existing = await db(SYNC_STATE_TABLE)
            .where('team_slug', slug)
            .first();
          if (existing) {
            await db(SYNC_STATE_TABLE)
              .where('team_slug', slug)
              .update({ updated_at: db.fn.now() });
          } else {
            await db(SYNC_STATE_TABLE).insert({
              team_slug: slug,
              source: 'backstage',
            });
          }
        }

        // Helper: Remove team from sync state
        async function removeSyncedTeam(teamSlug: string): Promise<void> {
          await db(SYNC_STATE_TABLE)
            .where('team_slug', teamSlug.toLowerCase())
            .delete();
        }

        // Initialize database
        await initDatabase(db);

        // Helper: Get all GitHub teams
        async function getGitHubTeams(): Promise<Map<string, GitHubTeam>> {
          const teams = new Map<string, GitHubTeam>();
          try {
            const response = await octokit.paginate(octokit.teams.list, {
              org: githubOrg!,
              per_page: 100,
            });
            for (const team of response) {
              teams.set(team.slug.toLowerCase(), {
                id: team.id,
                slug: team.slug,
                name: team.name,
              });
            }
          } catch (error) {
            logger.error('Failed to fetch GitHub teams', error as Error);
          }
          return teams;
        }

        // Helper: Get all Backstage groups with sync info
        async function getBackstageGroups(): Promise<
          Map<string, BackstageGroup>
        > {
          const groups = new Map<string, BackstageGroup>();
          try {
            const entities = await catalog.getEntities({
              filter: { kind: 'Group' },
            });

            for (const entity of entities.items) {
              const name = entity.metadata.name;
              const annotations = entity.metadata.annotations || {};

              // Check if this group came from GitHub (has github.com/team-slug)
              const isFromGitHub = !!annotations['github.com/team-slug'];

              // Check if this group should sync to GitHub
              const shouldSync = annotations['github.com/sync'] === 'true';

              // Get the role annotation for permission mapping
              const role = annotations['backstage.io/role'];

              // Skip system permission groups
              const isSystemGroup = [
                'admins',
                'editors',
                'viewers',
                'unassigned',
              ].includes(name);

              // Get members from relations
              const members: string[] = [];
              if (entity.relations) {
                for (const relation of entity.relations) {
                  if (
                    relation.type === 'hasMember' &&
                    relation.targetRef.startsWith('user:')
                  ) {
                    const username = relation.targetRef.split('/').pop();
                    if (username) {
                      members.push(username);
                    }
                  }
                }
              }

              // Include all groups for tracking, but mark which should sync
              if (!isFromGitHub && !isSystemGroup) {
                groups.set(name.toLowerCase(), {
                  name: entity.metadata.name,
                  description: entity.metadata.description,
                  members,
                  role,
                  shouldSync,
                });
              }
            }
          } catch (error) {
            logger.error('Failed to fetch Backstage groups', error as Error);
          }
          return groups;
        }

        // Helper: Create a GitHub team
        async function createGitHubTeam(
          name: string,
          description?: string,
        ): Promise<boolean> {
          try {
            logger.info(`Creating GitHub team: ${name}`);
            await octokit.teams.create({
              org: githubOrg!,
              name: name,
              description: description || `Team synced from Backstage`,
              privacy: 'closed',
            });
            logger.info(`Successfully created GitHub team: ${name}`);
            return true;
          } catch (error: any) {
            if (
              error.status === 422 &&
              error.message?.includes('already exists')
            ) {
              logger.info(`GitHub team already exists: ${name}`);
              return true;
            }
            logger.error(`Failed to create GitHub team: ${name}`, error);
            return false;
          }
        }

        // Helper: Delete a GitHub team
        async function deleteGitHubTeam(slug: string): Promise<boolean> {
          try {
            logger.info(`Deleting GitHub team: ${slug}`);
            await octokit.teams.deleteInOrg({
              org: githubOrg!,
              team_slug: slug,
            });
            logger.info(`Successfully deleted GitHub team: ${slug}`);
            return true;
          } catch (error: any) {
            if (error.status === 404) {
              logger.info(`GitHub team not found (already deleted): ${slug}`);
              return true;
            }
            logger.error(`Failed to delete GitHub team: ${slug}`, error);
            return false;
          }
        }

        // Helper: Sync team members
        // NOTE: Member sync is one-way from GitHub to Backstage by default.
        // Backstage groups don't typically have members defined - members come from GitHub.
        // This function only ADDS Backstage members to GitHub, it does NOT remove members.
        // To enable full bi-directional member sync, add annotation: github.com/manage-members: "true"
        async function syncTeamMembers(
          teamSlug: string,
          backstageMembers: string[],
          manageMembership: boolean = false,
        ): Promise<void> {
          try {
            // Get current GitHub team members
            const githubMembers = new Set<string>();
            try {
              const members = await octokit.paginate(
                octokit.teams.listMembersInOrg,
                {
                  org: githubOrg!,
                  team_slug: teamSlug,
                  per_page: 100,
                },
              );
              for (const member of members as Array<{ login?: string }>) {
                if (member.login) {
                  githubMembers.add(member.login.toLowerCase());
                }
              }
            } catch (error: any) {
              if (error.status !== 404) {
                throw error;
              }
            }

            const backstageMemberSet = new Set(
              backstageMembers.map(m => m.toLowerCase()),
            );

            // Add missing members from Backstage to GitHub
            for (const member of backstageMembers) {
              if (!githubMembers.has(member.toLowerCase())) {
                try {
                  await octokit.teams.addOrUpdateMembershipForUserInOrg({
                    org: githubOrg!,
                    team_slug: teamSlug,
                    username: member,
                    role: 'member',
                  });
                  logger.info(`Added ${member} to GitHub team ${teamSlug}`);
                } catch (error) {
                  logger.warn(
                    `Failed to add ${member} to team ${teamSlug}`,
                    error as Error,
                  );
                }
              }
            }

            // Only remove members if manageMembership is true AND Backstage has members defined
            // This prevents accidentally removing all members when Backstage group is empty
            if (manageMembership && backstageMembers.length > 0) {
              for (const member of githubMembers) {
                if (!backstageMemberSet.has(member)) {
                  try {
                    await octokit.teams.removeMembershipForUserInOrg({
                      org: githubOrg!,
                      team_slug: teamSlug,
                      username: member,
                    });
                    logger.info(
                      `Removed ${member} from GitHub team ${teamSlug}`,
                    );
                  } catch (error) {
                    logger.warn(
                      `Failed to remove ${member} from team ${teamSlug}`,
                      error as Error,
                    );
                  }
                }
              }
            }
          } catch (error) {
            logger.error(
              `Failed to sync members for team ${teamSlug}`,
              error as Error,
            );
          }
        }

        // Main sync function
        async function syncTeams(): Promise<void> {
          logger.info('Starting GitHub team sync...');

          try {
            const [githubTeams, backstageGroups, syncedTeams] =
              await Promise.all([
                getGitHubTeams(),
                getBackstageGroups(),
                getSyncedTeams(),
              ]);

            // Filter to only groups that should sync
            const groupsToSync = new Map<string, BackstageGroup>();
            for (const [key, group] of backstageGroups) {
              if (group.shouldSync) {
                groupsToSync.set(key, group);
              }
            }

            logger.info(
              `Found ${githubTeams.size} GitHub teams, ${backstageGroups.size} Backstage groups, ${groupsToSync.size} marked for sync, ${syncedTeams.size} previously synced`,
            );

            // Create/update GitHub teams for Backstage groups with sync annotation
            for (const [groupKey, group] of groupsToSync) {
              if (!githubTeams.has(groupKey)) {
                const created = await createGitHubTeam(
                  group.name,
                  group.description,
                );
                if (created) {
                  await addSyncedTeam(groupKey);
                  await syncTeamMembers(
                    group.name.toLowerCase(),
                    group.members,
                  );
                }
              } else {
                // Team exists, update sync state and sync members
                await addSyncedTeam(groupKey);
                await syncTeamMembers(groupKey, group.members);
              }
            }

            // Delete GitHub teams that were synced from Backstage but no longer exist
            // or no longer have the sync annotation
            for (const syncedTeam of syncedTeams) {
              if (!groupsToSync.has(syncedTeam)) {
                // Team was synced but no longer in Backstage or sync disabled
                if (githubTeams.has(syncedTeam)) {
                  logger.info(
                    `Group ${syncedTeam} no longer marked for sync, deleting from GitHub`,
                  );
                  const deleted = await deleteGitHubTeam(syncedTeam);
                  if (deleted) {
                    await removeSyncedTeam(syncedTeam);
                  }
                } else {
                  // Already gone from GitHub, clean up database
                  await removeSyncedTeam(syncedTeam);
                }
              }
            }

            logger.info('GitHub team sync completed');
          } catch (error) {
            logger.error('GitHub team sync failed', error as Error);
          }
        }

        // Schedule the sync task
        await scheduler.scheduleTask({
          id: 'github-team-sync',
          frequency: { minutes: 5 },
          timeout: { minutes: 3 },
          initialDelay: { seconds: 30 },
          fn: syncTeams,
        });

        logger.info('GitHub Team Sync plugin initialized');
        logger.info(
          `Sync state is persisted to database table: ${SYNC_STATE_TABLE}`,
        );
        logger.info(
          'To sync a group to GitHub, add annotation: github.com/sync: "true"',
        );
        logger.info(
          'To map a group to a role, add annotation: backstage.io/role: "editors"',
        );
      },
    });
  },
});

export default githubTeamSyncPlugin;
