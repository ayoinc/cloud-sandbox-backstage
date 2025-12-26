import {
  Button,
  Card,
  CardContent,
  CardHeader,
  Typography,
  makeStyles,
} from '@material-ui/core';
import GroupAddIcon from '@material-ui/icons/GroupAdd';
import PersonAddIcon from '@material-ui/icons/PersonAdd';
import GroupIcon from '@material-ui/icons/Group';
import { useNavigate } from 'react-router-dom';

const useStyles = makeStyles(theme => ({
  card: {
    height: '100%',
  },
  buttonContainer: {
    display: 'flex',
    flexDirection: 'column',
    gap: theme.spacing(2),
  },
  button: {
    justifyContent: 'flex-start',
    padding: theme.spacing(1.5, 2),
  },
  description: {
    marginBottom: theme.spacing(2),
    color: theme.palette.text.secondary,
  },
}));

export const GitHubOrgActionsCard = () => {
  const classes = useStyles();
  const navigate = useNavigate();

  const actions = [
    {
      title: 'Create GitHub Team',
      description: 'Create a new team in the GitHub organization',
      icon: <GroupAddIcon />,
      templateName: 'github-team-template',
      color: 'primary' as const,
    },
    {
      title: 'Invite User to Organization',
      description: 'Send an invitation to join the GitHub organization',
      icon: <PersonAddIcon />,
      templateName: 'github-user-invite-template',
      color: 'primary' as const,
    },
    {
      title: 'Add User to Team',
      description: 'Add an existing member to a GitHub team',
      icon: <GroupIcon />,
      templateName: 'github-team-member-template',
      color: 'default' as const,
    },
  ];

  const handleClick = (templateName: string) => {
    navigate(`/create/templates/default/${templateName}`);
  };

  return (
    <Card className={classes.card}>
      <CardHeader title="GitHub Organization Actions" />
      <CardContent>
        <Typography variant="body2" className={classes.description}>
          Manage your GitHub organization directly from Backstage. Changes will
          automatically sync back to the catalog.
        </Typography>
        <div className={classes.buttonContainer}>
          {actions.map(action => (
            <Button
              key={action.templateName}
              variant="outlined"
              color={action.color}
              className={classes.button}
              startIcon={action.icon}
              onClick={() => handleClick(action.templateName)}
              fullWidth
            >
              {action.title}
            </Button>
          ))}
        </div>
      </CardContent>
    </Card>
  );
};

export default GitHubOrgActionsCard;
