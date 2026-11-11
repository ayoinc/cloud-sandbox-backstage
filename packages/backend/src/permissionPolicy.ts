import {
  createBackendModule,
  coreServices,
} from '@backstage/backend-plugin-api';
import type { Entity } from '@backstage/catalog-model';
import {
  PolicyDecision,
  AuthorizeResult,
  isResourcePermission,
} from '@backstage/plugin-permission-common';
import {
  PermissionPolicy,
  PolicyQuery,
  PolicyQueryUser,
} from '@backstage/plugin-permission-node';
import { policyExtensionPoint } from '@backstage/plugin-permission-node/alpha';
import {
  catalogConditions,
  createCatalogConditionalDecision,
} from '@backstage/plugin-catalog-backend/alpha';
import {
  createScaffolderActionConditionalDecision,
  createScaffolderTaskConditionalDecision,
  scaffolderActionConditions,
  scaffolderTaskConditions,
} from '@backstage/plugin-scaffolder-backend/alpha';
import {
  catalogServiceRef,
  type CatalogService,
} from '@backstage/plugin-catalog-node';
import type { AuthService, LoggerService } from '@backstage/backend-plugin-api';
import {
  ACCOUNT_ANNOTATION,
  UNCLAIMED_ACCOUNT,
  directory,
} from './accounts/directory';
import { ADMIN_ONLY_ACTIONS } from './pipeline/adminActions';

/**
 * =============================================================================
 * Portal Permission Policy
 * =============================================================================
 *
 * Decides two things for every request: what the caller's role lets them
 * do, and which accounts' things they may do it to.
 *
 * Roles:
 * - admin: a portal administrator (the list kept by ./branding, and
 *   PORTAL_ADMINS), or a member of an admin group. Every permission.
 * - editor: a member of an editor group. Everything but deleting entities,
 *   unregistering files, the template editor and its dry run, and the
 *   template actions that change the operator's GitHub organisation.
 * - viewer: any other signed-in user. As an editor.
 * - guest: a caller with no user. Reading the catalog and TechDocs only.
 *
 * A portal administrator is told by their own user ref only. The groups a
 * sign-in names are not asked: they can come from a catalog file the
 * person registered themselves.
 *
 * Group roles are taken only from groups and user entries the operator
 * provides (files named in the configuration, the GitHub organisation
 * sync). Anyone can register a catalog file that defines a group called
 * `admins`, so entities that come from registered files, which carry the
 * `portal/account` annotation, grant nothing.
 *
 * Accounts (see ./accounts/directory.ts):
 * - A catalog entity that carries the `portal/account` annotation is
 *   private to that account. Every permission on a catalog entity that the
 *   role allows is answered with a condition: the entity has no such
 *   annotation, or it names one of the caller's accounts. That holds for
 *   every role, administrators included, and a caller with no user gets
 *   only the entities without the annotation. The catalog applies the
 *   condition, and search and TechDocs follow the catalog.
 * - A template run is private to the user who started it: reading and
 *   cancelling a run is answered with the condition that the caller
 *   created it, and denied to a caller with no user.
 *
 * Templates run with the portal's own GitHub token:
 * - The actions in ./pipeline/adminActions.ts change the operator's GitHub
 *   organisation (teams, members, invitations). Running an action is
 *   answered, for anyone but an admin, with the condition that it is none
 *   of those, so a template that uses one stops there.
 * - The template editor's dry run returns what it read, which can be any
 *   repository that token reads, so it and the editor are for admins.
 * =============================================================================
 */

// The resource types of the catalog's and the scaffolder's permissions, as
// their common packages define them.
const CATALOG_ENTITY = 'catalog-entity';
const SCAFFOLDER_TASK = 'scaffolder-task';
const SCAFFOLDER_ACTION = 'scaffolder-action';

// Whether an entity comes from a registered file, and so belongs to an account
const isPrivate = (entity: Entity) =>
  entity.metadata.annotations?.[ACCOUNT_ANNOTATION] !== undefined;

// Permissions that require admin role
const ADMIN_PERMISSIONS = [
  'catalog.entity.delete',
  'catalog.location.delete',
  'scaffolder.template.management',
  'scaffolder.template.dry-run',
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

export class GitHubOrgPermissionPolicy implements PermissionPolicy {
  private logger: LoggerService;
  private catalog: CatalogService;
  private auth: AuthService;
  private groupMembershipCache: Map<
    string,
    { groups: string[]; timestamp: number }
  > = new Map();
  private cacheTTL = 5 * 60 * 1000; // 5 minutes cache

  constructor(
    logger: LoggerService,
    catalog: CatalogService,
    auth: AuthService,
  ) {
    this.logger = logger;
    this.catalog = catalog;
    this.auth = auth;
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

      // Fetch the user entity from the catalog using this plugin's own service credentials
      const credentials = await this.auth.getOwnServiceCredentials();
      const userEntity = await this.catalog.getEntityByRef(
        `user:${namespace}/${name}`,
        { credentials },
      );

      if (!userEntity) {
        this.logger.debug(`User entity not found: ${userEntityRef}`);
        return [];
      }

      // Get memberOf from the user's spec, unless the user entry itself
      // comes from a registered file
      const memberOf = isPrivate(userEntity)
        ? []
        : (userEntity.spec as any)?.memberOf || [];
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
        const groupEntities = await this.catalog.getEntities(
          { filter: { kind: 'Group' } },
          { credentials },
        );

        for (const group of groupEntities.items) {
          // A group from a registered file grants no role
          if (isPrivate(group)) {
            continue;
          }
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
        this.logger.debug(
          'Error fetching groups for membership check',
          error as Error,
        );
      }

      // Update cache
      this.groupMembershipCache.set(userEntityRef, {
        groups,
        timestamp: Date.now(),
      });

      this.logger.debug(
        `User ${userEntityRef} belongs to groups: ${
          groups.join(', ') || 'none'
        }`,
      );
      return groups;
    } catch (error) {
      this.logger.error(
        `Failed to get user groups for ${userEntityRef}`,
        error as Error,
      );
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
   * Determine user's role: a portal administrator, or by group membership
   */
  private async getUserRole(
    userEntityRef: string | undefined,
  ): Promise<'admin' | 'editor' | 'viewer' | 'guest'> {
    if (!userEntityRef) {
      return 'guest';
    }

    if (await directory.isPortalAdmin(userEntityRef, [])) {
      this.logger.debug(`User ${userEntityRef} is a portal administrator`);
      return 'admin';
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
    user?: PolicyQueryUser,
  ): Promise<PolicyDecision> {
    const userEntityRef =
      user && this.auth.isPrincipal(user.credentials, 'user')
        ? user.credentials.principal.userEntityRef
        : undefined;
    const { permission } = request;
    const role = await this.getUserRole(userEntityRef);

    this.logger.debug(
      `Permission check: user=${userEntityRef}, permission=${permission.name}, role=${role}`,
    );

    // What the role allows comes first: a permission it is denied stays denied
    const decision = this.decideForRole(role, permission.name);
    if (decision.result !== AuthorizeResult.ALLOW) {
      return decision;
    }

    // Catalog entities: only those that are shared, or of the caller's accounts
    if (isResourcePermission(permission, CATALOG_ENTITY)) {
      const accounts = userEntityRef
        ? await directory.accountsOf(userEntityRef)
        : [];
      return createCatalogConditionalDecision(permission, {
        anyOf: [
          {
            not: catalogConditions.hasAnnotation({
              annotation: ACCOUNT_ANNOTATION,
            }),
          },
          ...accounts
            .filter(account => account !== UNCLAIMED_ACCOUNT)
            .map(account =>
              catalogConditions.hasAnnotation({
                annotation: ACCOUNT_ANNOTATION,
                value: account,
              }),
            ),
        ],
      });
    }

    // Template runs: only the caller's own
    if (isResourcePermission(permission, SCAFFOLDER_TASK)) {
      if (!userEntityRef) {
        return { result: AuthorizeResult.DENY };
      }
      return createScaffolderTaskConditionalDecision(permission, {
        anyOf: [
          scaffolderTaskConditions.isTaskOwner({ createdBy: [userEntityRef] }),
        ],
      });
    }

    // Template actions: those that change the operator's GitHub
    // organisation are for admins
    if (
      role !== 'admin' &&
      isResourcePermission(permission, SCAFFOLDER_ACTION)
    ) {
      const [first, ...others] = ADMIN_ONLY_ACTIONS.map(actionId =>
        scaffolderActionConditions.hasActionId({ actionId }),
      );
      if (first) {
        return createScaffolderActionConditionalDecision(permission, {
          not: { anyOf: [first, ...others] },
        });
      }
    }

    return decision;
  }

  private decideForRole(
    role: 'admin' | 'editor' | 'viewer' | 'guest',
    permissionName: string,
  ): { result: AuthorizeResult.ALLOW | AuthorizeResult.DENY } {
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
        auth: coreServices.auth,
        catalog: catalogServiceRef,
      },
      async init({ policy, logger, auth, catalog }) {
        logger.info('Initializing the portal permission policy');
        logger.info(
          '  - Portal administrators and admin groups ' +
            `(${ADMIN_GROUPS.join(', ')}): Full access`,
        );
        logger.info(
          `  - Editor groups (${EDITOR_GROUPS.join(
            ', ',
          )}): Create/modify access`,
        );
        logger.info('  - All authenticated users: viewer access');
        logger.info(
          'Entities from registered files are shown to their own account only',
        );
        policy.setPolicy(new GitHubOrgPermissionPolicy(logger, catalog, auth));
      },
    });
  },
});
