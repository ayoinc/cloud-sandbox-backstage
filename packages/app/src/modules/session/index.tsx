import {
  AppRootElementBlueprint,
  createFrontendModule,
} from '@backstage/frontend-plugin-api';
import { IdleTimeoutMonitor } from './IdleTimeoutMonitor';

const idleTimeoutMonitor = AppRootElementBlueprint.make({
  name: 'idle-timeout',
  params: { element: <IdleTimeoutMonitor /> },
});

export const sessionModule = createFrontendModule({
  pluginId: 'app',
  extensions: [idleTimeoutMonitor],
});
