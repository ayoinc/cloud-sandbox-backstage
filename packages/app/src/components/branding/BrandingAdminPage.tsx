import type { FC } from 'react';
import { Content, Header, Page } from '@backstage/core-components';
import { Grid } from '@material-ui/core';
import { BrandingProvider } from './BrandingContext';
import { BrandingSettingsPanel } from './BrandingSettingsPanel';
import { BrandingAdminManagement } from './BrandingAdminManagement';

/**
 * The branding controls: name, logo and theme on the left, who may change
 * them on the right. Shown as the Branding tab of Settings and at
 * /admin/branding.
 */
export const BrandingControls: FC = () => (
  <BrandingProvider>
    <Grid container spacing={3}>
      <Grid item xs={12} md={8}>
        <BrandingSettingsPanel />
      </Grid>
      <Grid item xs={12} md={4}>
        <BrandingAdminManagement />
      </Grid>
    </Grid>
  </BrandingProvider>
);

/** The branding controls as a page of their own. */
export const BrandingAdminPage: FC = () => (
  <Page themeId="tool">
    <Header
      title="Branding settings"
      subtitle="Set the name, logo and theme of this portal"
    />
    <Content>
      <BrandingControls />
    </Content>
  </Page>
);

export default BrandingAdminPage;
