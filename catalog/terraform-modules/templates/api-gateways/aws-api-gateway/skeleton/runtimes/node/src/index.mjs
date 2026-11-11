import { route } from './router.mjs';
import { routes } from './routes.mjs';

// Entry point of the Lambda function (handler "index.handler").
export const handler = event => route(routes, event);
