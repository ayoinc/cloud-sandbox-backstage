import {
  AppRootElementBlueprint,
  createFrontendModule,
} from '@backstage/frontend-plugin-api';
import { brandThemes, techDocsBrandAddon } from '@internal/brand';
import { OrganisationGate } from '../../components/organisation/OrganisationGate';

/**
 * Once someone has signed in, puts them at their organisation's address.
 * Its name, logo and theme are loaded before the app starts (App.tsx), and
 * go to the brand identity store, which themes the app.
 */
const organisationGate = AppRootElementBlueprint.make({
  name: 'organisation',
  params: { element: <OrganisationGate /> },
});

export const brandModule = createFrontendModule({
  pluginId: 'app',
  extensions: [...brandThemes, organisationGate],
});

export const brandTechDocsModule = createFrontendModule({
  pluginId: 'techdocs',
  extensions: [techDocsBrandAddon],
});
