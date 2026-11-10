import type { ReactNode } from 'react';
import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { AppRootWrapperBlueprint } from '@backstage/plugin-app-react';
import { useTheme } from '@material-ui/core';
import {
  BrandThemeProvider,
  brandThemes,
  brandTranslations,
  techDocsBrandAddon,
} from '@internal/brand';
import { BrandingProvider, useBranding } from '../../components/branding';

/** Re-themes the app with the admin-chosen primary colour, when one is set. */
const AdminColorOverride = ({ children }: { children: ReactNode }) => {
  const { settings } = useBranding();
  const mode = useTheme().palette.type === 'dark' ? 'dark' : 'light';
  if (!settings.primaryColor) {
    return <>{children}</>;
  }
  return (
    <BrandThemeProvider
      mode={mode}
      overrides={{ primaryColor: settings.primaryColor }}
    >
      {children}
    </BrandThemeProvider>
  );
};

/** Loads admin branding once for the whole app and applies it. */
const brandingRootWrapper = AppRootWrapperBlueprint.make({
  name: 'branding',
  params: {
    component: ({ children }) => (
      <BrandingProvider>
        <AdminColorOverride>{children}</AdminColorOverride>
      </BrandingProvider>
    ),
  },
});

export const brandModule = createFrontendModule({
  pluginId: 'app',
  extensions: [...brandThemes, brandTranslations, brandingRootWrapper],
});

export const brandTechDocsModule = createFrontendModule({
  pluginId: 'techdocs',
  extensions: [techDocsBrandAddon],
});
