import type { ReactNode } from 'react';
import {
  Content,
  ContentHeader,
  Header,
  HeaderLabel,
  Page,
  SupportButton,
} from '@backstage/core-components';
import {
  Button,
  Card,
  CardContent,
  CardHeader,
  Grid,
  Typography,
  makeStyles,
} from '@material-ui/core';
import GroupAddIcon from '@material-ui/icons/GroupAdd';
import PersonAddIcon from '@material-ui/icons/PersonAdd';
import GroupIcon from '@material-ui/icons/Group';
import SyncIcon from '@material-ui/icons/Sync';
import GitHubIcon from '@material-ui/icons/GitHub';
import { useNavigate } from 'react-router-dom';

const useStyles = makeStyles((theme) => ({
  card: {
    height: '100%',
    display: 'flex',
    flexDirection: 'column',
  },
  cardContent: {
    flexGrow: 1,
    display: 'flex',
    flexDirection: 'column',
  },
  button: {
    marginTop: 'auto',
    justifyContent: 'flex-start',
  },
  icon: {
    fontSize: 48,
    marginBottom: theme.spacing(2),
    color: theme.palette.primary.main,
  },
  description: {
    marginBottom: theme.spacing(2),
    color: theme.palette.text.secondary,
    flexGrow: 1,
  },
  infoCard: {
    backgroundColor: theme.palette.background.default,
    marginBottom: theme.spacing(3),
  },
  syncInfo: {
    display: 'flex',
    alignItems: 'center',
    gap: theme.spacing(1),
  },
}));

interface ActionCardProps {
  title: string;
  description: string;
  icon: ReactNode;
  buttonText: string;
  templateName: string;
}

const ActionCard = ({ title, description, icon, buttonText, templateName }: ActionCardProps) => {
  const classes = useStyles();
  const navigate = useNavigate();

  return (
    <Card className={classes.card}>
      <CardContent className={classes.cardContent}>
        <div>{icon}</div>
        <Typography variant="h6" gutterBottom>
          {title}
        </Typography>
        <Typography variant="body2" className={classes.description}>
          {description}
        </Typography>
        <Button
          variant="contained"
          color="primary"
          className={classes.button}
          onClick={() => navigate(`/create/templates/default/${templateName}`)}
          fullWidth
        >
          {buttonText}
        </Button>
      </CardContent>
    </Card>
  );
};

export const GitHubOrgPage = () => {
  const classes = useStyles();

  const actions = [
    {
      title: 'Create Team',
      description:
        'Create a new team in your GitHub organization. Teams help organize members and manage repository access.',
      icon: <GroupAddIcon className={classes.icon} />,
      buttonText: 'Create New Team',
      templateName: 'github-team-template',
    },
    {
      title: 'Invite User',
      description:
        'Send an invitation to a new user to join your GitHub organization. They will receive an email invitation.',
      icon: <PersonAddIcon className={classes.icon} />,
      buttonText: 'Invite New User',
      templateName: 'github-user-invite-template',
    },
    {
      title: 'Add User to Team',
      description:
        'Add an existing organization member to a team. You can assign them as a member or maintainer.',
      icon: <GroupIcon className={classes.icon} />,
      buttonText: 'Manage Team Membership',
      templateName: 'github-team-member-template',
    },
  ];

  return (
    <Page themeId="tool">
      <Header title="GitHub Organization" subtitle="Manage your GitHub organization from Backstage">
        <HeaderLabel label="Organization" value="ContainerCode" />
        <HeaderLabel label="Sync" value="Every 5 minutes" />
      </Header>
      <Content>
        <ContentHeader title="Organization Actions">
          <Button
            variant="outlined"
            color="primary"
            href="https://github.com/orgs/ContainerCode/people"
            target="_blank"
            startIcon={<GitHubIcon />}
          >
            View on GitHub
          </Button>
          <SupportButton>
            Manage your GitHub organization directly from Backstage.
            Changes made here will sync to GitHub, and changes in GitHub
            will sync back to Backstage automatically.
          </SupportButton>
        </ContentHeader>

        <Card className={classes.infoCard}>
          <CardContent>
            <div className={classes.syncInfo}>
              <SyncIcon color="primary" />
              <Typography variant="body1">
                <strong>Bi-directional Sync Active:</strong> Changes made in GitHub automatically sync to Backstage every 5 minutes.
                Changes made here in Backstage are immediately pushed to GitHub.
              </Typography>
            </div>
          </CardContent>
        </Card>

        <Grid container spacing={3}>
          {actions.map((action) => (
            <Grid item xs={12} md={4} key={action.templateName}>
              <ActionCard {...action} />
            </Grid>
          ))}
        </Grid>

        <Grid container spacing={3} style={{ marginTop: 24 }}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardHeader title="Quick Links" />
              <CardContent>
                <Grid container spacing={2}>
                  <Grid item xs={6}>
                    <Button
                      variant="outlined"
                      fullWidth
                      href="/catalog?filters[kind]=user"
                      startIcon={<PersonAddIcon />}
                    >
                      View All Users
                    </Button>
                  </Grid>
                  <Grid item xs={6}>
                    <Button
                      variant="outlined"
                      fullWidth
                      href="/catalog?filters[kind]=group"
                      startIcon={<GroupIcon />}
                    >
                      View All Teams
                    </Button>
                  </Grid>
                  <Grid item xs={6}>
                    <Button
                      variant="outlined"
                      fullWidth
                      href="https://github.com/orgs/ContainerCode/teams"
                      target="_blank"
                      startIcon={<GitHubIcon />}
                    >
                      GitHub Teams
                    </Button>
                  </Grid>
                  <Grid item xs={6}>
                    <Button
                      variant="outlined"
                      fullWidth
                      href="https://github.com/orgs/ContainerCode/people/pending_invitations"
                      target="_blank"
                      startIcon={<GitHubIcon />}
                    >
                      Pending Invitations
                    </Button>
                  </Grid>
                </Grid>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={6}>
            <Card>
              <CardHeader title="How It Works" />
              <CardContent>
                <Typography variant="body2" paragraph>
                  <strong>GitHub to Backstage:</strong> Users and teams from your GitHub organization
                  are automatically synced to Backstage every 5 minutes.
                </Typography>
                <Typography variant="body2" paragraph>
                  <strong>Backstage to GitHub:</strong> When you create a team or invite a user
                  using the actions above, they are immediately created in GitHub. The next sync
                  will bring them into Backstage.
                </Typography>
                <Typography variant="body2">
                  <strong>Note:</strong> User invitations require the invitee to accept via email
                  before they appear in the organization.
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Content>
    </Page>
  );
};

export default GitHubOrgPage;
