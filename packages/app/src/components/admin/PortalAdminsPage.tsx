import { Content, Header, Page } from '@backstage/core-components';
import { Grid } from '@material-ui/core';
import { PortalAdmins } from './PortalAdmins';
import { PortalOrganisations } from './PortalOrganisations';

/**
 * The list of portal administrators as a page of its own, with the list of
 * every organisation they can remove.
 */
export const PortalAdminsPage = () => (
  <Page themeId="tool">
    <Header
      title="Portal administrators"
      subtitle="The people who administer this portal"
    />
    <Content>
      <Grid container>
        <Grid item xs={12} md={8}>
          <PortalAdmins />
          <PortalOrganisations />
        </Grid>
      </Grid>
    </Content>
  </Page>
);
