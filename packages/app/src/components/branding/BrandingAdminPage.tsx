import type { FC } from 'react';
import { Content, Header, Page } from '@backstage/core-components';
import { Grid } from '@material-ui/core';
import { BrandingProvider } from './BrandingContext';
import { BrandingSettingsPanel } from './BrandingSettingsPanel';
import { BrandingAdminManagement } from './BrandingAdminManagement';

/**
 * Admin page for branding settings.
 * Only visible to admin users.
 */
export const BrandingAdminPage: FC = () => {
  return (
    <BrandingProvider>
      <Page themeId="tool">
        <Header title="Branding Settings" subtitle="Customize your Backstage instance" />
        <Content>
          <Grid container spacing={3}>
            <Grid item xs={12} md={8}>
              <BrandingSettingsPanel />
            </Grid>
            <Grid item xs={12} md={4}>
              <BrandingAdminManagement />
            </Grid>
          </Grid>
        </Content>
      </Page>
    </BrandingProvider>
  );
};

export default BrandingAdminPage;
