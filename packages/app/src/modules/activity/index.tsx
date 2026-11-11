import {
  AppRootElementBlueprint,
  createFrontendModule,
} from '@backstage/frontend-plugin-api';
import { RunActivity } from './RunActivity';

const runActivity = AppRootElementBlueprint.make({
  name: 'run-activity',
  params: { element: <RunActivity /> },
});

/** Shows the progress of a template run in the corner of its task page. */
export const activityModule = createFrontendModule({
  pluginId: 'app',
  extensions: [runActivity],
});
