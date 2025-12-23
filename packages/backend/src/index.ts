/*
 * Hi!
 *
 * Note that this is an EXAMPLE Backstage backend. Please check the README.
 *
 * Happy hacking!
 */

import { createBackend } from '@backstage/backend-defaults';

const backend = createBackend();

backend.add(import('@backstage/plugin-app-backend'));
backend.add(import('@backstage/plugin-proxy-backend'));

// scaffolder plugin
backend.add(import('@backstage/plugin-scaffolder-backend'));
backend.add(import('@backstage/plugin-scaffolder-backend-module-github'));
backend.add(
  import('@backstage/plugin-scaffolder-backend-module-notifications'),
);

// techdocs plugin
backend.add(import('@backstage/plugin-techdocs-backend'));

// auth plugin
backend.add(import('@backstage/plugin-auth-backend'));
// See https://backstage.io/docs/backend-system/building-backends/migrating#the-auth-plugin

// Guest auth provider - allows unauthenticated access for TechDocs
backend.add(import('@backstage/plugin-auth-backend-module-guest-provider'));

// GitHub Auth provider with custom sign-in resolver
// Allows sign-in with real GitHub users without requiring pre-existing catalog users
backend.add(import('./githubAuthResolver'));

// catalog plugin
backend.add(import('@backstage/plugin-catalog-backend'));
backend.add(
  import('@backstage/plugin-catalog-backend-module-scaffolder-entity-model'),
);

// GitHub org entity provider - syncs teams and members from GitHub org
backend.add(import('@backstage/plugin-catalog-backend-module-github-org'));

// See https://backstage.io/docs/features/software-catalog/configuration#subscribing-to-catalog-errors
backend.add(import('@backstage/plugin-catalog-backend-module-logs'));

// permission plugin
backend.add(import('@backstage/plugin-permission-backend'));
// Custom permission policy that restricts guest users
backend.add(import('./permissionPolicy'));

// Branding settings plugin - admin-only logo and org name customization
backend.add(import('./brandingSettingsPlugin'));

// search plugin
backend.add(import('@backstage/plugin-search-backend'));

// search engine
// See https://backstage.io/docs/features/search/search-engines
// Default: PostgreSQL search (works without external dependencies)
backend.add(import('@backstage/plugin-search-backend-module-pg'));

// =============================================================================
// OPTIONAL: Elasticsearch Search Engine
// =============================================================================
// For production deployments with large catalogs, Elasticsearch provides
// better search performance and features. To enable:
// 1. Uncomment the line below
// 2. Comment out the pg search module above
// 3. Configure elasticsearch in app-config.yaml
// 4. Ensure Elasticsearch is running and accessible
// =============================================================================
// backend.add(import('@backstage/plugin-search-backend-module-elasticsearch'));

// search collators
backend.add(import('@backstage/plugin-search-backend-module-catalog'));
backend.add(import('@backstage/plugin-search-backend-module-techdocs'));

// kubernetes plugin
backend.add(import('@backstage/plugin-kubernetes-backend'));

// notifications and signals plugins
backend.add(import('@backstage/plugin-notifications-backend'));
backend.add(import('@backstage/plugin-signals-backend'));

// =============================================================================
// Events Backend - Event-driven architecture support (FUTURE)
// =============================================================================
// The events backend provides infrastructure for event publishing/subscribing
// Used by catalog, scaffolder, and other plugins to emit events
// 
// NOTE: Disabled due to TypeScript bundler module resolution issues.
// The @backstage/plugin-events-backend package cannot be resolved during
// live TypeScript compilation in development mode.
// 
// RabbitMQ is available in the Docker Compose stack for future integration.
// To implement RabbitMQ events, consider:
// 1. Pre-compiling the backend before running
// 2. Using a separate microservice to consume Backstage webhooks
// 3. Waiting for Backstage to fix bundler resolution for events-backend
// =============================================================================
// backend.add(import('@backstage/plugin-events-backend'));

// =============================================================================
// PLACEHOLDER: Enterprise Backend Plugins (uncomment when configured)
// =============================================================================
// To enable these plugins, configure the corresponding settings in:
// - app-config.yaml (plugin configuration)
// - .env (environment variables)
// - packages/app/src/components/catalog/EntityPage.tsx (frontend components)
// =============================================================================

// SonarQube backend - Code quality metrics
// Requires: SONARQUBE_BASE_URL, SONARQUBE_API_KEY in .env
// backend.add(import('@backstage/plugin-sonarqube-backend'));

// ArgoCD scaffolder actions - GitOps deployments
// Requires: ARGOCD_BASE_URL, ARGOCD_USERNAME, ARGOCD_PASSWORD in .env
// backend.add(import('@roadiehq/scaffolder-backend-argocd'));

// HTTP Request scaffolder actions - For GitHub API and AWX/Ansible API calls
backend.add(import('@roadiehq/scaffolder-backend-module-http-request'));

// Scaffolder utilities - Extra scaffolder helper actions
backend.add(import('@roadiehq/scaffolder-backend-module-utils'));

backend.start();
