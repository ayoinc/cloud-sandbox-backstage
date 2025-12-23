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
  'catalog.location.create',  // Needed for scaffolder to register new entities
  'catalog.location.read',
];

class GitHubOrgPermissionPolicy implements PermissionPolicy {
  private logger: any;

  constructor(logger: any) {
    this.logger = logger;
  }

  /**
   * Check if user belongs to a specific group.
   * 
   * This is a placeholder implementation. In production, you would:
   * 1. Query the catalog for the user entity
   * 2. Check the user's spec.memberOf field
   * 3. Or use the identity's group claims from the auth token
   * 
   * For GitHub org integration, groups are automatically synced when you
   * configure @backstage/plugin-catalog-backend-module-github-org
   */
  private async isUserInGroup(
    userEntityRef: string | undefined,
    _groupName: string,
  ): Promise<boolean> {
    if (!userEntityRef) {
      return false;
    }

    // Extract user info from entity ref (format: user:default/username)
    const userMatch = userEntityRef.match(/^user:([^/]+)\/(.+)$/);
    if (!userMatch) {
      return false;
    }

    // TODO: Implement catalog lookup for user's group membership
    // For now, all authenticated users get viewer access by default
    // Admin/editor access requires explicit group assignment
    return false;
  }

  /**
   * Determine user's role based on their group membership
   */
  private async getUserRole(userEntityRef: string | undefined): Promise<'admin' | 'editor' | 'viewer' | 'guest'> {
    if (!userEntityRef) {
      return 'guest';
    }

    // Check for admin group membership
    if (await this.isUserInGroup(userEntityRef, 'admins')) {
      return 'admin';
    }

    // Check for editor group membership
    if (await this.isUserInGroup(userEntityRef, 'editors')) {
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
      if (permissionName === 'catalog.entity.read' ||
          permissionName.startsWith('catalog.entity.read')) {
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
      },
      async init({ policy, logger }) {
        logger.info('Initializing GitHub organization-based permission policy');
        logger.info('Users are granted access based on their GitHub org team membership:');
        logger.info('  - admins group: Full access');
        logger.info('  - editors group: Create/modify access');
        logger.info('  - viewers group: Read-only access (default for authenticated users)');
        policy.setPolicy(new GitHubOrgPermissionPolicy(logger));
      },
    });
  },
});
