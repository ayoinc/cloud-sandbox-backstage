import { screen } from '@testing-library/react';
import { mockApis, renderInTestApp } from '@backstage/frontend-test-utils';
import {
  discoveryApiRef,
  errorApiRef,
  githubAuthApiRef,
} from '@backstage/core-plugin-api';
import { BrandThemeProvider } from '../theme/BrandThemeProvider';
import { BrandedSignInPage, brandSignInProviders } from './BrandedSignInPage';

describe('BrandedSignInPage', () => {
  it('renders the branded layout around the core provider cards', async () => {
    renderInTestApp(
      <BrandThemeProvider mode="light">
        <BrandedSignInPage
          onSignInSuccess={jest.fn()}
          providers={brandSignInProviders}
        />
      </BrandThemeProvider>,
      {
        config: { app: { title: 'Cloud Sandbox' } },
        apis: [
          [githubAuthApiRef, { getBackstageIdentity: async () => undefined }],
          [discoveryApiRef, mockApis.discovery()],
          [errorApiRef, { post: jest.fn(), error$: jest.fn() }],
        ],
      },
    );

    expect(
      await screen.findByRole(
        'heading',
        { level: 1, name: 'Sign in to Cloud Sandbox' },
        { timeout: 5000 },
      ),
    ).toBeInTheDocument();
    expect(
      await screen.findByText('Sign in with your GitHub account.', undefined, {
        timeout: 5000,
      }),
    ).toBeInTheDocument();
    expect(screen.getByText('Guest')).toBeInTheDocument();
    expect(
      screen.getByRole('img', { name: 'Solirius Reply' }),
    ).toBeInTheDocument();
    expect(screen.getAllByRole('main')).toHaveLength(1);
  });
});
