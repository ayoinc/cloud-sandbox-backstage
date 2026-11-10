import { createApp } from '@backstage/frontend-defaults';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import { adminModule } from './modules/admin';
import { authModule } from './modules/auth';
import { brandModule, brandTechDocsModule } from './modules/brand';
import { catalogModule } from './modules/catalog';
import { homeModule } from './modules/home';
import { navModule } from './modules/nav';
import { catalogImportModule, scaffolderModule } from './modules/permissions';
import { sessionModule } from './modules/session';

export default createApp({
  features: [
    catalogPlugin,
    brandModule,
    brandTechDocsModule,
    navModule,
    homeModule,
    authModule,
    sessionModule,
    adminModule,
    catalogModule,
    catalogImportModule,
    scaffolderModule,
  ],
});
