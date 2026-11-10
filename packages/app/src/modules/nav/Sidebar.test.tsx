import { renderTestApp } from '@backstage/frontend-test-utils';
import catalogPlugin from '@backstage/plugin-catalog/alpha';
import notificationsPlugin from '@backstage/plugin-notifications/alpha';
import { screen } from '@testing-library/react';
import { brandModule } from '../brand';
import { navModule } from '.';

describe('Sidebar', () => {
  it('renders one catalog shortcut per entity kind', async () => {
    renderTestApp({
      features: [catalogPlugin, notificationsPlugin, brandModule, navModule],
    });

    const expected = {
      Components: 'component',
      APIs: 'api',
      Resources: 'resource',
      Templates: 'template',
      Domains: 'domain',
      Systems: 'system',
      Groups: 'group',
      Users: 'user',
    };
    for (const [text, kind] of Object.entries(expected)) {
      expect(await screen.findByRole('link', { name: text })).toHaveAttribute(
        'href',
        `/catalog?filters[kind]=${kind}`,
      );
    }
    expect(screen.getByText('Sign Out')).toBeInTheDocument();
  });
});
