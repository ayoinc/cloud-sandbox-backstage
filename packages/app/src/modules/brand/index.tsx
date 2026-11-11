import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { AppRootWrapperBlueprint } from '@backstage/plugin-app-react';
import {
  brandThemes,
  brandTranslations,
  techDocsBrandAddon,
} from '@internal/brand';
import { BrandingProvider } from '../../components/branding';

/**
 * Loads the branding settings once for the whole app. What it loads goes to
 * the brand identity store, which themes the app and supplies the name and
 * logo wherever they appear.
 */
const brandingRootWrapper = AppRootWrapperBlueprint.make({
  name: 'branding',
  params: {
    component: ({ children }) => (
      <BrandingProvider>{children}</BrandingProvider>
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
