import {
  createBackendModule,
  coreServices,
} from '@backstage/backend-plugin-api';
import {
  PolicyDecision,
  AuthorizeResult,
} from '@backstage/plugin-permission-common';
import {
  PermissionPolicy,
  PolicyQuery,
} from '@backstage/plugin-permission-node';
import { policyExtensionPoint } from '@backstage/plugin-permission-node/alpha';
import { BackstageIdentityResponse } from '@backstage/plugin-auth-node';
import { catalogServiceRef } from '@backstage/plugin-catalog-node/alpha';
import type { CatalogApi } from '@backstage/catalog-client';
import type { LoggerService } from '@backstage/backend-plugin-api';

/**
 * =============================================================================
 * GitHub Organization-Based Permission Policy
 * =============================================================================
 *
 * This permission policy grants access based on the user's group membership
 * in the Backstage catalog. Groups are synced from GitHub organization teams.
 *
 * Configuration:
 * 1. Set up GitHub OAuth (GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET)
 * 2. Configure GitHub org integration in app-config.yaml
 * 3. Map GitHub teams to Backstage groups in catalog/users.yaml
 *
 * Role Hierarchy:
 * - admins: Full access to all features
 * - editors: Can create/modify entities and use scaffolder
 * - viewers: Read-only access (default for authenticated users)
 *
 * Users without group membership get viewer-level access by default.
 * =============================================================================
 */

// Permissions that require admin role
const ADMIN_PERMISSIONS = [
  'catalog.entity.delete',
  'catalog.location.delete',
];

// Permissions that editors and viewers can use (for scaffolder workflows)
const SCAFFOLDER_CATALOG_PERMISSIONS = [
  'catalog.location.create', // Needed for scaffolder to register new entities
  'catalog.location.read',
];

// Admin group names (case-insensitive matching)
const ADMIN_GROUPS = ['admins', 'platform-admins', 'backstage-admins'];

// Editor group names (case-insensitive matching)
const EDITOR_GROUPS = ['editors', 'developers', 'platform-editors'];

class GitHubOrgPermissionPolicy implements PermissionPolicy {
  private logger: LoggerService;
  private catalog: CatalogApi;
  private groupMembershipCache: Map<string, { groups: string[]; timestamp: number }> = new Map();
  private cacheTTL = 5 * 60 * 1000; // 5 minutes cache

  constructor(logger: LoggerService, catalog: CatalogApi) {
    this.logger = logger;
    this.catalog = catalog;
  }

  /**
   * Get user's group memberships from the catalog.
   * Results are cached to avoid excessive catalog queries.
   */
  private async getUserGroups(userEntityRef: string): Promise<string[]> {
    // Check cache first
    const cached = this.groupMembershipCache.get(userEntityRef);
    if (cached && Date.now() - cached.timestamp < this.cacheTTL) {
      return cached.groups;
    }

    try {
      // Parse user entity ref (format: user:default/username)
      const match = userEntityRef.match(/^user:([^/]+)\/(.+)$/);
      if (!match) {
        return [];
      }

      const [, namespace, name] = match;

      // Fetch the user entity from the catalog
      const userEntity = await this.catalog.getEntityByRef(`user:${namespace}/${name}`);

      if (!userEntity) {
        this.logger.debug(`User entity not found: ${userEntityRef}`);
        return [];
      }

      // Get memberOf from the user's spec
      const memberOf = (userEntity.spec as any)?.memberOf || [];
      const groups: string[] = [];

      for (const groupRef of memberOf) {
        // Normalize group reference
        let normalizedRef = groupRef.toLowerCase();
        if (!normalizedRef.includes(':')) {
          normalizedRef = `group:default/${normalizedRef}`;
        } else if (!normalizedRef.includes('/')) {
          const [kind, groupName] = normalizedRef.split(':');
          normalizedRef = `${kind}:default/${groupName}`;
        }

        // Extract just the group name for role checking
        const groupMatch = normalizedRef.match(/group:[^/]+\/(.+)$/);
        if (groupMatch) {
          groups.push(groupMatch[1].toLowerCase());
        }
      }

      // Also check for groups that have this user as a member
      // This handles the reverse relationship (group.members contains user)
      try {
        const groupEntities = await this.catalog.getEntities({
          filter: { kind: 'Group' },
        });

        for (const group of groupEntities.items) {
          const members = (group.spec as any)?.members || [];
          const groupName = group.metadata.name.toLowerCase();

          // Check if user is a member of this group
          for (const member of members) {
            const memberNormalized = member.toLowerCase();
            if (
              memberNormalized === name.toLowerCase() ||
              memberNormalized === `user:${namespace}/${name}`.toLowerCase() ||
              memberNormalized === `user:default/${name}`.toLowerCase()
            ) {
              if (!groups.includes(groupName)) {
                groups.push(groupName);
              }
            }
          }
        }
      } catch (error) {
        this.logger.debug('Error fetching groups for membership check', error as Error);
      }

      // Update cache
      this.groupMembershipCache.set(userEntityRef, {
        groups,
        timestamp: Date.now(),
      });

      this.logger.debug(`User ${userEntityRef} belongs to groups: ${groups.join(', ') || 'none'}`);
      return groups;
    } catch (error) {
      this.logger.error(`Failed to get user groups for ${userEntityRef}`, error as Error);
      return [];
    }
  }

  /**
   * Check if user belongs to any of the specified groups.
   */
  private async isUserInAnyGroup(
    userEntityRef: string | undefined,
    targetGroups: string[],
  ): Promise<boolean> {
    if (!userEntityRef) {
      return false;
    }

    const userGroups = await this.getUserGroups(userEntityRef);

    for (const group of targetGroups) {
      if (userGroups.includes(group.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /**
   * Determine user's role based on their group membership
   */
  private async getUserRole(
    userEntityRef: string | undefined,
  ): Promise<'admin' | 'editor' | 'viewer' | 'guest'> {
    if (!userEntityRef) {
      return 'guest';
    }

    // Check for admin group membership
    if (await this.isUserInAnyGroup(userEntityRef, ADMIN_GROUPS)) {
      this.logger.debug(`User ${userEntityRef} has admin role`);
      return 'admin';
    }

    // Check for editor group membership
    if (await this.isUserInAnyGroup(userEntityRef, EDITOR_GROUPS)) {
      this.logger.debug(`User ${userEntityRef} has editor role`);
      return 'editor';
    }

    // All authenticated users get at least viewer access
    // Guests (no userEntityRef) are denied access
    if (userEntityRef.startsWith('user:')) {
      return 'viewer';
    }

    return 'guest';
  }

  async handle(
    request: PolicyQuery,
    user?: BackstageIdentityResponse,
  ): Promise<PolicyDecision> {
    const userEntityRef = user?.identity?.userEntityRef;
    const permissionName = request.permission.name;
    const role = await this.getUserRole(userEntityRef);

    this.logger.debug(
      `Permission check: user=${userEntityRef}, permission=${permissionName}, role=${role}`,
    );

    // Guests (unauthenticated) - allow read-only access to TechDocs and Catalog
    if (role === 'guest') {
      // Allow TechDocs read access for public documentation
      if (permissionName.startsWith('techdocs.')) {
        return { result: AuthorizeResult.ALLOW };
      }
      // Allow catalog read access for browsing entities
      if (
        permissionName === 'catalog.entity.read' ||
        permissionName.startsWith('catalog.entity.read')
      ) {
        return { result: AuthorizeResult.ALLOW };
      }
      this.logger.info(`Denying ${permissionName} for unauthenticated user`);
      return { result: AuthorizeResult.DENY };
    }

    // Admins - allow everything
    if (role === 'admin') {
      return { result: AuthorizeResult.ALLOW };
    }

    // Editors - allow editor and viewer permissions
    if (role === 'editor') {
      if (ADMIN_PERMISSIONS.includes(permissionName)) {
        return { result: AuthorizeResult.DENY };
      }
      return { result: AuthorizeResult.ALLOW };
    }

    // Viewers - authenticated users with read + scaffolder access
    if (role === 'viewer') {
      // Deny admin permissions
      if (ADMIN_PERMISSIONS.includes(permissionName)) {
        return { result: AuthorizeResult.DENY };
      }

      // Allow scaffolder permissions for authenticated users
      // They can view templates and create tasks from them
      if (permissionName.startsWith('scaffolder.')) {
        return { result: AuthorizeResult.ALLOW };
      }

      // Allow catalog.location.create for scaffolder workflows
      // This is needed so scaffolder can register newly created repos in the catalog
      if (SCAFFOLDER_CATALOG_PERMISSIONS.includes(permissionName)) {
        return { result: AuthorizeResult.ALLOW };
      }

      // Allow read operations
      return { result: AuthorizeResult.ALLOW };
    }

    // Default: deny unknown roles
    return { result: AuthorizeResult.DENY };
  }
}

export default createBackendModule({
  pluginId: 'permission',
  moduleId: 'github-org-policy',
  register(reg) {
    reg.registerInit({
      deps: {
        policy: policyExtensionPoint,
        logger: coreServices.logger,
        catalog: catalogServiceRef,
      },
      async init({ policy, logger, catalog }) {
        logger.info('Initializing GitHub organization-based permission policy');
        logger.info(
          'Users are granted access based on their GitHub org team membership:',
        );
        logger.info(`  - Admin groups (${ADMIN_GROUPS.join(', ')}): Full access`);
        logger.info(`  - Editor groups (${EDITOR_GROUPS.join(', ')}): Create/modify access`);
        logger.info('  - All authenticated users: Read-only access (viewer)');
        logger.info('Group membership is now resolved via catalog lookup');
        policy.setPolicy(new GitHubOrgPermissionPolicy(logger, catalog as CatalogApi));
      },
    });
  },
});
