import {
  createFrontendModule,
  PageBlueprint,
  SubPageBlueprint,
} from '@backstage/frontend-plugin-api';

// These pages render their own Page/Header, so the framework page header is
// suppressed. They have no nav icon and are reached by direct URL, as before.

const brandingAdminPage = PageBlueprint.make({
  name: 'branding-admin',
  params: {
    path: '/admin/branding',
    title: 'Branding Settings',
    noHeader: true,
    loader: () =>
      import('../../components/branding').then(m => <m.BrandingAdminPage />),
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

export const adminModule = createFrontendModule({
  pluginId: 'app',
  extensions: [brandingAdminPage, ownershipManagementPage, githubOrgPage],
});

// Branding is a tab of Settings, beside General and Authentication
// Providers, which is where people look for it.
const brandingSettingsTab = SubPageBlueprint.make({
  name: 'branding',
  params: {
    path: 'branding',
    title: 'Branding',
    loader: async () => {
      const [m, { Content }] = await Promise.all([
        import('../../components/branding'),
        import('@backstage/core-components'),
      ]);
      return (
        <Content>
          <m.BrandingControls />
        </Content>
      );
    },
  },
});

export const settingsModule = createFrontendModule({
  pluginId: 'user-settings',
  extensions: [brandingSettingsTab],
});
