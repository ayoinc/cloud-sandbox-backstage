/**
 * Permission policy: runs the real policy with a catalog and a directory of
 * accounts and administrators made up for each test.
 */

import type {
  AuthService,
  BackstageCredentials,
  LoggerService,
} from '@backstage/backend-plugin-api';
import type { Entity } from '@backstage/catalog-model';
import {
  AuthorizeResult,
  createPermission,
} from '@backstage/plugin-permission-common';
import type { PolicyQueryUser } from '@backstage/plugin-permission-node';
import type { CatalogService } from '@backstage/plugin-catalog-node';
import { provide } from '../accounts/directory';
import { GitHubOrgPermissionPolicy } from '../permissionPolicy';

const JANE = 'user:default/jane';
const ORGANISATION = 'organisation:0123456789abcdef0123456789abcdef';
const ANNOTATION = 'portal/account';

const entityRead = createPermission({
  name: 'catalog.entity.read',
  attributes: { action: 'read' },
  resourceType: 'catalog-entity',
});
const entityDelete = createPermission({
  name: 'catalog.entity.delete',
  attributes: { action: 'delete' },
  resourceType: 'catalog-entity',
});
const taskRead = createPermission({
  name: 'scaffolder.task.read',
  attributes: { action: 'read' },
  resourceType: 'scaffolder-task',
});
const taskCancel = createPermission({
  name: 'scaffolder.task.cancel',
  attributes: {},
  resourceType: 'scaffolder-task',
});
const taskCreate = createPermission({
  name: 'scaffolder.task.create',
  attributes: { action: 'create' },
});
const locationCreate = createPermission({
  name: 'catalog.location.create',
  attributes: { action: 'create' },
});
const locationDelete = createPermission({
  name: 'catalog.location.delete',
  attributes: { action: 'delete' },
});
const techdocsRead = createPermission({
  name: 'techdocs.entity.read',
  attributes: { action: 'read' },
});
const actionExecute = createPermission({
  name: 'scaffolder.action.execute',
  attributes: {},
  resourceType: 'scaffolder-action',
});
const templateManagement = createPermission({
  name: 'scaffolder.template.management',
  attributes: {},
});
const templateDryRun = createPermission({
  name: 'scaffolder.template.dry-run',
  attributes: {},
});

/** The condition every decision about a catalog entity starts with. */
const shared = {
  not: {
    rule: 'HAS_ANNOTATION',
    resourceType: 'catalog-entity',
    params: { annotation: ANNOTATION },
  },
};
const ofAccount = (value: string) => ({
  rule: 'HAS_ANNOTATION',
  resourceType: 'catalog-entity',
  params: { annotation: ANNOTATION, value },
});
const entitiesOf = (...accounts: string[]) => ({
  result: AuthorizeResult.CONDITIONAL,
  pluginId: 'catalog',
  resourceType: 'catalog-entity',
  conditions: { anyOf: [shared, ...accounts.map(ofAccount)] },
});
const tasksOf = (userRef: string) => ({
  result: AuthorizeResult.CONDITIONAL,
  pluginId: 'scaffolder',
  resourceType: 'scaffolder-task',
  conditions: {
    anyOf: [
      {
        rule: 'IS_TASK_OWNER',
        resourceType: 'scaffolder-task',
        params: { createdBy: [userRef] },
      },
    ],
  },
});
const DENY = { result: AuthorizeResult.DENY };
const ALLOW = { result: AuthorizeResult.ALLOW };

function signedIn(
  userEntityRef: string,
  ownershipEntityRefs = [userEntityRef],
): PolicyQueryUser {
  return {
    credentials: {
      $$type: '@backstage/BackstageCredentials',
      principal: { type: 'user', userEntityRef },
    } as BackstageCredentials,
    info: { userEntityRef, ownershipEntityRefs },
  };
}

function group(name: string, members: string[], account?: string): Entity {
  return {
    apiVersion: 'backstage.io/v1alpha1',
    kind: 'Group',
    metadata: {
      name,
      annotations: account ? { [ANNOTATION]: account } : {},
    },
    spec: { type: 'team', children: [], members },
  };
}

function userEntry(name: string, memberOf: string[], account?: string): Entity {
  return {
    apiVersion: 'backstage.io/v1alpha1',
    kind: 'User',
    metadata: {
      name,
      annotations: account ? { [ANNOTATION]: account } : {},
    },
    spec: { memberOf },
  };
}

/** A policy over a catalog that holds `entities`. */
function policyOver(entities: Entity[] = []) {
  const refOf = (entity: Entity) =>
    `${entity.kind}:${entity.metadata.namespace ?? 'default'}/${
      entity.metadata.name
    }`.toLowerCase();
  const catalog = {
    getEntityByRef: async (ref: string) =>
      entities.find(entity => refOf(entity) === ref),
    getEntities: async () => ({
      items: entities.filter(entity => entity.kind === 'Group'),
    }),
  } as unknown as CatalogService;
  const auth = {
    isPrincipal: (credentials: BackstageCredentials, type: string) =>
      (credentials.principal as { type: string }).type === type,
    getOwnServiceCredentials: async () => ({}),
  } as unknown as AuthService;
  const logger = {
    debug() {},
    info() {},
    warn() {},
    error() {},
  } as unknown as LoggerService;
  return new GitHubOrgPermissionPolicy(logger, catalog, auth);
}

/** Who is in which accounts and who administers the portal, for one test. */
function directoryOf(options: {
  accounts?: Record<string, string[]>;
  admins?: string[];
}) {
  provide({
    accountsOf: async userRef => options.accounts?.[userRef] ?? [userRef],
    accountFor: async userRef =>
      (options.accounts?.[userRef] ?? [userRef]).at(-1)!,
  });
  provide({
    isPortalAdmin: async (userRef, ownershipRefs) =>
      [userRef, ...ownershipRefs].some(ref => options.admins?.includes(ref)),
    portalAdmins: async () => options.admins ?? [],
  });
}

describe('Permission policy', () => {
  beforeEach(() => directoryOf({}));

  describe('catalog entities', () => {
    it('shows someone in no organisation the shared entities and their own', async () => {
      const decision = await policyOver().handle(
        { permission: entityRead },
        signedIn(JANE),
      );
      expect(decision).toEqual(entitiesOf(JANE));
    });

    it("shows a member their own entities and their organisation's", async () => {
      directoryOf({ accounts: { [JANE]: [JANE, ORGANISATION] } });
      const decision = await policyOver().handle(
        { permission: entityRead },
        signedIn(JANE),
      );
      expect(decision).toEqual(entitiesOf(JANE, ORGANISATION));
    });

    it('shows a caller with no user only the shared entities', async () => {
      const decision = await policyOver().handle({ permission: entityRead });
      expect(decision).toEqual(entitiesOf());
    });

    it('gives a portal administrator no other account’s entities', async () => {
      directoryOf({ admins: [JANE] });
      const policy = policyOver();
      expect(
        await policy.handle({ permission: entityRead }, signedIn(JANE)),
      ).toEqual(entitiesOf(JANE));
      expect(
        await policy.handle({ permission: entityDelete }, signedIn(JANE)),
      ).toEqual(entitiesOf(JANE));
    });

    it('makes nobody an administrator for a group their sign-in names', async () => {
      // The groups of a sign-in can come from a catalog file the person
      // registered themselves.
      directoryOf({ admins: ['group:default/platform'] });
      const decision = await policyOver().handle(
        { permission: entityDelete },
        signedIn(JANE, [JANE, 'group:default/platform']),
      );
      expect(decision).toEqual(DENY);
    });

    it('keeps a permission the role is denied, denied', async () => {
      const policy = policyOver();
      expect(
        await policy.handle({ permission: entityDelete }, signedIn(JANE)),
      ).toEqual(DENY);
      expect(await policy.handle({ permission: entityDelete })).toEqual(DENY);
    });
  });

  describe('template runs', () => {
    it('lets a user read and cancel only the runs they started', async () => {
      const policy = policyOver();
      expect(
        await policy.handle({ permission: taskRead }, signedIn(JANE)),
      ).toEqual(tasksOf(JANE));
      expect(
        await policy.handle({ permission: taskCancel }, signedIn(JANE)),
      ).toEqual(tasksOf(JANE));
    });

    it('holds a portal administrator to their own runs too', async () => {
      directoryOf({ admins: [JANE] });
      const decision = await policyOver().handle(
        { permission: taskRead },
        signedIn(JANE),
      );
      expect(decision).toEqual(tasksOf(JANE));
    });

    it('denies a caller with no user', async () => {
      const policy = policyOver();
      expect(await policy.handle({ permission: taskRead })).toEqual(DENY);
      expect(await policy.handle({ permission: taskCancel })).toEqual(DENY);
    });

    it('still lets a signed-in user start a run', async () => {
      const decision = await policyOver().handle(
        { permission: taskCreate },
        signedIn(JANE),
      );
      expect(decision).toEqual(ALLOW);
    });
  });

  describe('roles', () => {
    it('takes the admin role from a group the operator provides', async () => {
      const policy = policyOver([
        userEntry('jane', []),
        group('admins', ['jane']),
      ]);
      expect(
        await policy.handle({ permission: entityDelete }, signedIn(JANE)),
      ).toEqual(entitiesOf(JANE));
      expect(
        await policy.handle({ permission: locationDelete }, signedIn(JANE)),
      ).toEqual(ALLOW);
    });

    it('takes no role from a group that comes from a registered file', async () => {
      const policy = policyOver([
        userEntry('jane', []),
        group('admins', ['jane'], JANE),
      ]);
      expect(
        await policy.handle({ permission: entityDelete }, signedIn(JANE)),
      ).toEqual(DENY);
      expect(
        await policy.handle({ permission: locationDelete }, signedIn(JANE)),
      ).toEqual(DENY);
    });

    it('takes no role from a user entry that comes from a registered file', async () => {
      const policy = policyOver([userEntry('jane', ['admins'], JANE)]);
      expect(
        await policy.handle({ permission: locationDelete }, signedIn(JANE)),
      ).toEqual(DENY);
    });

    it('takes the role a user entry the operator provides names', async () => {
      const policy = policyOver([userEntry('jane', ['admins'])]);
      expect(
        await policy.handle({ permission: locationDelete }, signedIn(JANE)),
      ).toEqual(ALLOW);
    });
  });

  describe('everything else', () => {
    it('is as the role allows', async () => {
      const policy = policyOver();
      expect(
        await policy.handle({ permission: locationCreate }, signedIn(JANE)),
      ).toEqual(ALLOW);
      expect(
        await policy.handle({ permission: locationDelete }, signedIn(JANE)),
      ).toEqual(DENY);
      expect(await policy.handle({ permission: techdocsRead })).toEqual(ALLOW);
      expect(await policy.handle({ permission: locationCreate })).toEqual(DENY);
    });
  });

  describe('templates, which run with the portal’s own GitHub token', () => {
    const notOrganisationActions = {
      result: AuthorizeResult.CONDITIONAL,
      pluginId: 'scaffolder',
      resourceType: 'scaffolder-action',
      conditions: {
        not: {
          anyOf: [
            'github:team:create',
            'github:team:member:add',
            'github:org:invitation:create',
          ].map(actionId => ({
            rule: 'HAS_ACTION_ID',
            resourceType: 'scaffolder-action',
            params: { actionId },
          })),
        },
      },
    };

    it('keeps the actions that change the GitHub organisation for administrators', async () => {
      const policy = policyOver([
        userEntry('kim', []),
        group('editors', ['kim']),
      ]);
      expect(
        await policy.handle({ permission: actionExecute }, signedIn(JANE)),
      ).toEqual(notOrganisationActions);
      expect(
        await policy.handle(
          { permission: actionExecute },
          signedIn('user:default/kim'),
        ),
      ).toEqual(notOrganisationActions);
      expect(await policy.handle({ permission: actionExecute })).toEqual(DENY);

      directoryOf({ admins: [JANE] });
      expect(
        await policy.handle({ permission: actionExecute }, signedIn(JANE)),
      ).toEqual(ALLOW);
    });

    it('keeps the template editor and its dry run for administrators', async () => {
      const policy = policyOver();
      for (const permission of [templateManagement, templateDryRun]) {
        expect(await policy.handle({ permission }, signedIn(JANE))).toEqual(
          DENY,
        );
        expect(await policy.handle({ permission })).toEqual(DENY);
      }

      directoryOf({ admins: [JANE] });
      for (const permission of [templateManagement, templateDryRun]) {
        expect(await policy.handle({ permission }, signedIn(JANE))).toEqual(
          ALLOW,
        );
      }
    });
  });
});
