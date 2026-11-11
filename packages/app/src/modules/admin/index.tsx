import {
  AppRootElementBlueprint,
  createFrontendModule,
  PageBlueprint,
  SubPageBlueprint,
} from '@backstage/frontend-plugin-api';
import { FirstAdminClaim } from '../../components/admin/FirstAdminClaim';

// These pages render their own Page/Header, so the framework page header is
// suppressed. They have no nav icon and are reached by direct URL, as before.

const portalAdminsPage = PageBlueprint.make({
  name: 'portal-admins',
  params: {
    path: '/admin/administrators',
    title: 'Portal administrators',
    noHeader: true,
    loader: () =>
      import('../../components/admin/PortalAdminsPage').then(m => (
        <m.PortalAdminsPage />
      )),
  },
});

const ownershipManagementPage = PageBlueprint.make({
  name: 'ownership-management',
  params: {
    path: '/admin/ownership',
    title: 'Ownership Management',
    noHeader: true,
    loader: () =>
      import('../../components/ownership').then(m => (
        <m.OwnershipManagementPage />
      )),
  },
});

const githubOrgPage = PageBlueprint.make({
  name: 'github-org',
  params: {
    path: '/github-org',
    title: 'GitHub Organization',
    noHeader: true,
    loader: () =>
      import('../../components/github').then(m => <m.GitHubOrgPage />),
  },
});

const firstAdminClaim = AppRootElementBlueprint.make({
  name: 'first-admin-claim',
  params: { element: <FirstAdminClaim /> },
});

export const adminModule = createFrontendModule({
  pluginId: 'app',
  extensions: [
    portalAdminsPage,
    ownershipManagementPage,
    githubOrgPage,
    firstAdminClaim,
  ],
});

// The organisation is a tab of Settings, beside General and Authentication
// Providers, which is where people look for it.
const organisationSettingsTab = SubPageBlueprint.make({
  name: 'organisation',
  params: {
    path: 'organisation',
    title: 'Organisation',
    loader: async () => {
      const [m, { Content }] = await Promise.all([
        import('../../components/organisation/OrganisationPage'),
        import('@backstage/core-components'),
      ]);
      return (
        <Content>
          <m.OrganisationControls />
        </Content>
      );
    },
  },
});

export const settingsModule = createFrontendModule({
  pluginId: 'user-settings',
  extensions: [organisationSettingsTab],
});
