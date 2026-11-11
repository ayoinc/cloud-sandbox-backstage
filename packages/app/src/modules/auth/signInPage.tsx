import { configApiRef, useApi } from '@backstage/frontend-plugin-api';
import type { IdentityApi } from '@backstage/core-plugin-api';
import { SignInPageBlueprint } from '@backstage/plugin-app-react';
import {
  BrandedSignInPage,
  brandSignInProviders,
  organisationPath,
  organisationSlug,
} from '@internal/brand';

/**
 * Loads the app again at the address of the organisation the person who
 * has just signed in belongs to, or at the portal's own when they are in
 * none, unless they are already there. The organisation's name and look
 * are read when the app loads, so signing in at another address would
 * otherwise leave the look of the address the sign-in page was at: the
 * owner who signed out at the portal root came back without their
 * organisation's look, and someone else who signed in at it was left at
 * an organisation's address that is not theirs.
 */
async function placeAfterSignIn(identityApi: IdentityApi, backendUrl: string) {
  const { token } = await identityApi.getCredentials();
  const response = await fetch(`${backendUrl}/api/organisations/`, {
    headers: token ? { authorization: `Bearer ${token}` } : {},
  });
  if (!response.ok) {
    // The app's own check, once it has loaded, tries again.
    return;
  }
  const { organisation } = (await response.json()) as {
    organisation: { slug: string } | null;
  };
  const home = organisation?.slug ?? null;
  const { pathname, search, hash } = window.location;
  if (organisationSlug(pathname) !== home) {
    window.location.replace(organisationPath(home, pathname) + search + hash);
  }
}

/** Offers the sign-in providers that `auth.providers` lists for this deployment. */
export const signInPage = SignInPageBlueprint.make({
  params: {
    loader: async () => props => {
      const config = useApi(configApiRef);
      const enabled = config.getOptionalConfig('auth.providers')?.keys() ?? [];
      const backendUrl = config.getString('backend.baseUrl');
      const providers = brandSignInProviders.filter(choice =>
        enabled.includes(choice.provider),
      );
      return (
        <BrandedSignInPage
          {...props}
          providers={providers}
          onSignInSuccess={identityApi => {
            props.onSignInSuccess(identityApi);
            placeAfterSignIn(identityApi, backendUrl).catch(() => {
              // Left where it is; the app's own check tries again.
            });
          }}
        />
      );
    },
  },
});
