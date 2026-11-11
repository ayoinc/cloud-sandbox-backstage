import { coreComponentsTranslationRef } from '@backstage/core-components/alpha';
import { createTranslationMessages } from '@backstage/frontend-plugin-api';
import { TranslationBlueprint } from '@backstage/plugin-app-react';

/**
 * Plain-English, sentence-case copy for the core sign-in components
 * (GOV.UK content style). Install in the `app` frontend module.
 */
export const brandTranslations = TranslationBlueprint.make({
  name: 'brand-core-components',
  params: {
    resource: createTranslationMessages({
      ref: coreComponentsTranslationRef,
      messages: {
        'signIn.title': 'Sign in',
        'signIn.loginFailed': 'Sign in failed',
        'signIn.guestProvider.title': 'Guest',
        'signIn.guestProvider.enter': 'Continue as guest',
        'signIn.guestProvider.subtitle':
          'Use the portal without an account. You will not have a verified identity, so some features will not be available.',
      },
    }),
  },
});
