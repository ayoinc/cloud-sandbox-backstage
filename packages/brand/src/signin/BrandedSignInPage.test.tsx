import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { mockApis, renderInTestApp } from '@backstage/frontend-test-utils';
import {
  discoveryApiRef,
  errorApiRef,
  githubAuthApiRef,
} from '@backstage/core-plugin-api';
import { setBrandIdentity } from '../identity/brandIdentity';
import { BrandThemeProvider } from '../theme/BrandThemeProvider';
import { BrandedSignInPage } from './BrandedSignInPage';
import { brandSignInProviders } from './SignInChoices';

const REMEMBERED_KEY = '@backstage/core:SignInPage:provider';
const JANE = {
  token: 'a-token',
  identity: {
    type: 'user' as const,
    userEntityRef: 'user:default/jane',
    ownershipEntityRefs: ['user:default/jane'],
  },
};

/** GitHub as the page uses it: nobody signed in until `signedIn` says so. */
const github = (signedIn: { silently?: boolean; whenAsked?: boolean }) => ({
  getBackstageIdentity: jest.fn(async (options?: { optional?: boolean }) => {
    if (options?.optional) {
      return signedIn.silently ? JANE : undefined;
    }
    if (!signedIn.whenAsked) {
      throw new Error('The window was closed');
    }
    return JANE;
  }),
  getProfile: async () => ({ displayName: 'Jane' }),
  signOut: jest.fn(async () => {}),
});

/** A token shaped as the guest sign-in reads it: its expiry is in the middle. */
const guestToken = [
  'e30',
  btoa(JSON.stringify({ exp: Math.floor(Date.now() / 1000) + 3600 })),
  'signature',
].join('.');

const render = (
  options: {
    github?: ReturnType<typeof github>;
    onSignInSuccess?: jest.Mock;
    errors?: jest.Mock;
  } = {},
) =>
  renderInTestApp(
    <BrandThemeProvider mode="light">
      <BrandedSignInPage
        onSignInSuccess={options.onSignInSuccess ?? jest.fn()}
        providers={brandSignInProviders}
      />
    </BrandThemeProvider>,
    {
      config: { app: { title: 'Developer Portal' } },
      apis: [
        [githubAuthApiRef, options.github ?? github({})],
        [discoveryApiRef, mockApis.discovery()],
        [errorApiRef, { post: options.errors ?? jest.fn(), error$: jest.fn() }],
      ],
    },
  );

describe('BrandedSignInPage', () => {
  beforeEach(() => {
    setBrandIdentity({});
    window.localStorage.clear();
  });

  it('names no organisation and shows no logo until one is set', async () => {
    render();
    expect(
      await screen.findByRole(
        'heading',
        { level: 1, name: 'Sign in' },
        { timeout: 5000 },
      ),
    ).toBeInTheDocument();
    // One button for each way in, and nothing else to press.
    expect(
      screen.getAllByRole('button').map(button => button.textContent),
    ).toEqual([
      'Continue with GitHub',
      'Continue with Google',
      'Continue as guest',
    ]);
    expect(screen.queryByRole('img')).not.toBeInTheDocument();
    expect(screen.getAllByRole('main')).toHaveLength(1);
    expect(
      screen.getByRole('link', { name: 'Privacy notice' }),
    ).toHaveAttribute('href', '/privacy.html');
  });

  it('signs in with the provider chosen and remembers the choice', async () => {
    const onSignInSuccess = jest.fn();
    const api = github({ whenAsked: true });
    render({ github: api, onSignInSuccess });
    await userEvent.click(
      await screen.findByRole('button', { name: 'Continue with GitHub' }),
    );
    await waitFor(() => expect(onSignInSuccess).toHaveBeenCalledTimes(1));
    // The provider's window is asked for at once, on the click.
    expect(api.getBackstageIdentity).toHaveBeenCalledWith({
      instantPopup: true,
    });
    expect(window.localStorage.getItem(REMEMBERED_KEY)).toBe(
      'github-auth-provider',
    );
    expect(
      (await onSignInSuccess.mock.calls[0][0].getBackstageIdentity())
        .userEntityRef,
    ).toBe('user:default/jane');
  });

  it('forgets a choice that did not sign in, and says why', async () => {
    const errors = jest.fn();
    const onSignInSuccess = jest.fn();
    render({ github: github({}), onSignInSuccess, errors });
    await userEvent.click(
      await screen.findByRole('button', { name: 'Continue with GitHub' }),
    );
    await waitFor(() => expect(errors).toHaveBeenCalledTimes(1));
    expect(errors.mock.calls[0][0].message).toBe(
      'Could not sign you in. Try again, or choose another way. (The window was closed)',
    );
    expect(onSignInSuccess).not.toHaveBeenCalled();
    expect(window.localStorage.getItem(REMEMBERED_KEY)).toBeNull();
    // The buttons are there to try again.
    expect(
      screen.getByRole('button', { name: 'Continue with GitHub' }),
    ).toBeEnabled();
  });

  it('signs a remembered user back in without asking', async () => {
    window.localStorage.setItem(REMEMBERED_KEY, 'github-auth-provider');
    const onSignInSuccess = jest.fn();
    const api = github({ silently: true });
    render({ github: api, onSignInSuccess });
    await waitFor(() => expect(onSignInSuccess).toHaveBeenCalledTimes(1));
    expect(api.getBackstageIdentity).toHaveBeenCalledWith({ optional: true });
  });

  it('offers the buttons when the remembered user is no longer signed in', async () => {
    window.localStorage.setItem(REMEMBERED_KEY, 'github-auth-provider');
    const errors = jest.fn();
    const onSignInSuccess = jest.fn();
    render({ github: github({}), onSignInSuccess, errors });
    expect(
      await screen.findByRole('button', { name: 'Continue with GitHub' }),
    ).toBeEnabled();
    expect(onSignInSuccess).not.toHaveBeenCalled();
    expect(errors).not.toHaveBeenCalled();
  });

  it('signs out of the provider and forgets the choice', async () => {
    window.localStorage.setItem(REMEMBERED_KEY, 'github-auth-provider');
    const onSignInSuccess = jest.fn();
    const api = github({ silently: true });
    render({ github: api, onSignInSuccess });
    await waitFor(() => expect(onSignInSuccess).toHaveBeenCalledTimes(1));
    await onSignInSuccess.mock.calls[0][0].signOut();
    expect(api.signOut).toHaveBeenCalledTimes(1);
    expect(window.localStorage.getItem(REMEMBERED_KEY)).toBeNull();
  });

  it('signs a guest in, and ends the guest session on sign-out', async () => {
    const requests: [string, string][] = [];
    global.fetch = jest.fn(
      async (url: RequestInfo | URL, init?: RequestInit) => {
        requests.push([init?.method ?? 'GET', String(url)]);
        return new Response(
          JSON.stringify({
            profile: {},
            backstageIdentity: {
              token: guestToken,
              identity: {
                type: 'user',
                userEntityRef: 'user:development/guest',
                ownershipEntityRefs: ['user:development/guest'],
              },
            },
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        );
      },
    );
    const onSignInSuccess = jest.fn();
    render({ onSignInSuccess });
    await userEvent.click(
      await screen.findByRole('button', { name: 'Continue as guest' }),
    );
    await waitFor(() => expect(onSignInSuccess).toHaveBeenCalledTimes(1));
    expect(window.localStorage.getItem(REMEMBERED_KEY)).toBe('guest');
    expect(requests[0][1]).toMatch(/\/api\/auth\/guest\/refresh$/);

    await onSignInSuccess.mock.calls[0][0].signOut();
    expect(requests.at(-1)).toEqual([
      'POST',
      expect.stringMatching(/\/api\/auth\/guest\/logout$/),
    ]);
    expect(window.localStorage.getItem(REMEMBERED_KEY)).toBeNull();
  });

  it("shows the organisation's name and logo once they are set", async () => {
    setBrandIdentity({
      name: 'Acme',
      logoFullUrl: '/api/organisations/acme/logo/full?v=1',
    });
    render();
    expect(
      await screen.findByRole(
        'heading',
        { level: 1, name: 'Sign in to Acme' },
        { timeout: 5000 },
      ),
    ).toBeInTheDocument();
    expect(screen.getByRole('img', { name: 'Acme' })).toHaveAttribute(
      'src',
      '/api/organisations/acme/logo/full?v=1',
    );
  });
});
