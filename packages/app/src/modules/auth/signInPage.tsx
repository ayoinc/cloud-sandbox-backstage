import { configApiRef, useApi } from '@backstage/frontend-plugin-api';
import { SignInPageBlueprint } from '@backstage/plugin-app-react';
import { BrandedSignInPage, brandSignInProviders } from '@internal/brand';

/** Offers the sign-in providers that `auth.providers` lists for this deployment. */
export const signInPage = SignInPageBlueprint.make({
  params: {
    loader: async () => props => {
      const enabled =
        useApi(configApiRef).getOptionalConfig('auth.providers')?.keys() ?? [];
      const providers = brandSignInProviders.filter(choice =>
        enabled.includes(choice.provider),
      );
      return <BrandedSignInPage {...props} providers={providers} />;
    },
  },
});
