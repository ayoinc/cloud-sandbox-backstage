import { createBackendModule } from '@backstage/backend-plugin-api';
import {
  authProvidersExtensionPoint,
  createOAuthProviderFactory,
} from '@backstage/plugin-auth-node';
import { githubAuthenticator } from '@backstage/plugin-auth-backend-module-github-provider';
import { stringifyEntityRef, DEFAULT_NAMESPACE } from '@backstage/catalog-model';

/**
 * =============================================================================
 * GitHub OAuth Authentication Module
 * =============================================================================
 * 
 * This module provides GitHub OAuth authentication for Backstage. Users are
 * authenticated via their GitHub account and user entities are automatically
 * created based on their GitHub username.
 * 
 * Configuration Required (in .env or app-config.yaml):
 * - GITHUB_CLIENT_ID: OAuth App Client ID from GitHub
 * - GITHUB_CLIENT_SECRET: OAuth App Client Secret from GitHub
 * - GITHUB_TOKEN: Personal Access Token for API access (optional, for org sync)
 * 
 * How It Works:
 * 1. User clicks "Sign in with GitHub"
 * 2. GitHub OAuth flow authenticates the user
 * 3. User's GitHub username becomes their Backstage identity
 * 4. No pre-existing catalog user entry is required
 * 
 * Group Membership:
 * - Users can be assigned to groups manually in catalog/users.yaml
 * - Or automatically synced from GitHub org teams using:
 *   @backstage/plugin-catalog-backend-module-github-org
 * 
 * @see https://backstage.io/docs/auth/github/provider
 * @see https://backstage.io/docs/integrations/github/org
 * =============================================================================
 */
export default createBackendModule({
  pluginId: 'auth',
  moduleId: 'github-auth-resolver',
  register(reg) {
    reg.registerInit({
      deps: {
        providers: authProvidersExtensionPoint,
      },
      async init({ providers }) {
        providers.registerProvider({
          providerId: 'github',
          factory: createOAuthProviderFactory({
            authenticator: githubAuthenticator,
            async signInResolver({ result }, ctx) {
              // Get GitHub profile information
              const { username } = result.fullProfile;
              
              if (!username) {
                throw new Error(
                  'GitHub login failed: GitHub profile does not contain a username. ' +
                  'Please ensure your GitHub account has a public username.',
                );
              }

              // Create a lowercase username for consistent entity references
              const normalizedUsername = username.toLowerCase();

              // Create the user entity reference
              // Format: user:default/<github-username>
              const userEntityRef = stringifyEntityRef({
                kind: 'User',
                namespace: DEFAULT_NAMESPACE,
                name: normalizedUsername,
              });

              // Issue the authentication token
              // The token includes:
              // - sub: The user's entity reference (their identity)
              // - ent: Array of entity references the user owns (for ownership checks)
              return ctx.issueToken({
                claims: {
                  sub: userEntityRef,
                  ent: [userEntityRef],
                },
              });
            },
          }),
        });
      },
    });
  },
});
