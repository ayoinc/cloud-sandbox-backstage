import React from 'react';
import { UserSettingsPage } from '@backstage/plugin-user-settings';
import { BrandingProvider, BrandingSettingsPanel } from '../branding';
import { Box } from '@material-ui/core';

/**
 * Custom Settings Page that extends the default UserSettingsPage
 * with admin-only branding settings panel.
 */
export const CustomSettingsPage: React.FC = () => {
  return (
    <BrandingProvider>
      <Box>
        {/* Admin-only branding settings panel */}
        <BrandingSettingsPanel />
        
        {/* Default user settings */}
        <UserSettingsPage />
      </Box>
    </BrandingProvider>
  );
};

export default CustomSettingsPage;
