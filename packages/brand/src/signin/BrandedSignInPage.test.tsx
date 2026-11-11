import { screen } from '@testing-library/react';
import { mockApis, renderInTestApp } from '@backstage/frontend-test-utils';
import {
  discoveryApiRef,
  errorApiRef,
  githubAuthApiRef,
} from '@backstage/core-plugin-api';
import { setBrandIdentity } from '../identity/brandIdentity';
import { BrandThemeProvider } from '../theme/BrandThemeProvider';
import { BrandedSignInPage, brandSignInProviders } from './BrandedSignInPage';

const render = () =>
  renderInTestApp(
    <BrandThemeProvider mode="light">
      <BrandedSignInPage
        onSignInSuccess={jest.fn()}
        providers={brandSignInProviders}
      />
    </BrandThemeProvider>,
    {
      config: { app: { title: 'Developer Portal' } },
      apis: [
        [githubAuthApiRef, { getBackstageIdentity: async () => undefined }],
        [discoveryApiRef, mockApis.discovery()],
        [errorApiRef, { post: jest.fn(), error$: jest.fn() }],
      ],
    },
  );

describe('BrandedSignInPage', () => {
  beforeEach(() => {
    // The settings request fails here, which leaves the identity as set.
    global.fetch = jest.fn().mockRejectedValue(new Error('offline'));
    setBrandIdentity({});
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
    expect(
      await screen.findByText('Sign in with your GitHub account.', undefined, {
        timeout: 5000,
      }),
    ).toBeInTheDocument();
    expect(screen.getByText('Guest')).toBeInTheDocument();
    expect(screen.queryByRole('img')).not.toBeInTheDocument();
    expect(screen.queryByText(/Built and run by/)).not.toBeInTheDocument();
    expect(screen.getAllByRole('main')).toHaveLength(1);
  });

  it("shows the organisation's name and logo once they are set", async () => {
    setBrandIdentity({
      organizationName: 'Acme',
      logoFullUrl: '/api/branding-settings/logo/full?v=1',
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
      '/api/branding-settings/logo/full?v=1',
    );
    expect(screen.getByText('Built and run by Acme.')).toBeInTheDocument();
  });
});
