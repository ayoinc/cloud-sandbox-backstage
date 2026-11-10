import {
  createFrontendModule,
  PageBlueprint,
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
