import { createFrontendModule } from '@backstage/frontend-plugin-api';
import { signInPage } from './signInPage';

export const authModule = createFrontendModule({
  pluginId: 'app',
  extensions: [signInPage],
});
