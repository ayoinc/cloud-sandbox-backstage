/*
 * The backend the portal pipelines run in GitHub Actions.
 *
 * The deployed portal is a Cloudflare Worker that cannot run Backstage's Node
 * backend, so the work that needs it happens here instead: the catalog reads
 * and processes the entity files, and the scaffolder runs template steps.
 * `edge/scripts/pipeline` starts this backend, takes what it produced and
 * pushes it to the Worker.
 *
 * It is configured by `app-config.pipeline.yaml` alone and holds only the
 * plugins that work needs. The scaffolder action modules must stay the same
 * as in `index.ts`, so a template behaves the same in both backends.
 */

import { createBackend } from '@backstage/backend-defaults';

const backend = createBackend();

backend.add(import('@backstage/plugin-catalog-backend'));
// Lets the catalog validate Template entities
backend.add(
  import('@backstage/plugin-catalog-backend-module-scaffolder-entity-model'),
);

backend.add(import('@backstage/plugin-scaffolder-backend'));
backend.add(import('@backstage/plugin-scaffolder-backend-module-github'));
backend.add(import('@roadiehq/scaffolder-backend-module-http-request'));
backend.add(import('@roadiehq/scaffolder-backend-module-utils'));

// The portal decides who may start a template before a run reaches here
backend.add(import('@backstage/plugin-permission-backend'));
backend.add(
  import('@backstage/plugin-permission-backend-module-allow-all-policy'),
);

backend.start();
