import { useState, useEffect, useCallback } from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  Box,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  CircularProgress,
  Chip,
} from '@material-ui/core';
import { Alert } from '@material-ui/lab';
import { makeStyles } from '@material-ui/core/styles';
import DeleteIcon from '@material-ui/icons/Delete';
import { useApi, fetchApiRef } from '@backstage/core-plugin-api';
import { organisationPath } from '@internal/brand';
import {
  ORGANISATIONS_API,
  answer,
  shortName,
} from '../organisation/OrganisationContext';

const useStyles = makeStyles(theme => ({
  root: {
    marginBottom: theme.spacing(3),
  },
  list: {
    backgroundColor: theme.palette.background.paper,
  },
  listItem: {
    borderBottom: `1px solid ${theme.palette.divider}`,
  },
  chip: {
    marginRight: theme.spacing(6),
  },
  emptyState: {
    textAlign: 'center',
    padding: theme.spacing(4),
    color: theme.palette.text.secondary,
  },
  metadata: {
    fontSize: '0.75rem',
    color: theme.palette.text.secondary,
  },
}));

/** An organisation as the backend lists it for a portal administrator. */
interface OrganisationSummary {
  slug: string;
  name: string;
  members: number;
  owners: string[];
}

/**
 * Every organisation on the portal, for its administrators: name, address,
 * how many people are in it and who owns it. An administrator can remove
 * one, and nothing else: its name, look and members are its owners' to
 * change.
 */
export const PortalOrganisations: React.FC = () => {
  const classes = useStyles();
  const fetchApi = useApi(fetchApiRef);
  const [organisations, setOrganisations] = useState<OrganisationSummary[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [removing, setRemoving] = useState<string | null>(null);

  const fetchOrganisations = useCallback(async () => {
    try {
      setError(null);
      const data = await answer<{ organisations: OrganisationSummary[] }>(
        await fetchApi.fetch(`${ORGANISATIONS_API}?scope=portal`),
        'Failed to load the organisations',
      );
      setOrganisations(data.organisations);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Failed to load the organisations',
      );
    } finally {
      setIsLoading(false);
    }
  }, [fetchApi]);

  useEffect(() => {
    fetchOrganisations();
  }, [fetchOrganisations]);

  const handleRemove = async ({ slug, name, members }: OrganisationSummary) => {
    if (
      // eslint-disable-next-line no-alert
      !window.confirm(
        `Remove ${name}? Its address, logos and member list go with it, for ${
          members === 1 ? 'its 1 member' : `all ${members} of its members`
        }. What it registered in the catalog passes to its longest-standing owner. This cannot be undone.`,
      )
    ) {
      return;
    }
    try {
      setRemoving(slug);
      setError(null);
      await answer<void>(
        await fetchApi.fetch(`${ORGANISATIONS_API}/${slug}`, {
          method: 'DELETE',
        }),
        'Failed to remove the organisation',
      );
      await fetchOrganisations();
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : 'Failed to remove the organisation',
      );
    } finally {
      setRemoving(null);
    }
  };

  if (isLoading) {
    return (
      <Card className={classes.root}>
        <CardContent>
          <Box display="flex" justifyContent="center" p={3}>
            <CircularProgress />
          </Box>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className={classes.root}>
      <CardHeader
        title="Organisations"
        subheader="Every organisation on this portal"
      />
      <CardContent>
        {error && (
          <Alert severity="error" style={{ marginBottom: 16 }}>
            {error}
          </Alert>
        )}

        {organisations.length === 0 ? (
          <Box className={classes.emptyState}>
            <Typography variant="body1">No organisations yet.</Typography>
            <Typography variant="body2">
              Anyone who signs in with their own account can create one.
            </Typography>
          </Box>
        ) : (
          <List className={classes.list}>
            {organisations.map(organisation => (
              <ListItem key={organisation.slug} className={classes.listItem}>
                <ListItemText
                  primary={organisation.name}
                  secondary={
                    <span className={classes.metadata}>
                      {organisationPath(organisation.slug)}
                      {' · '}
                      {organisation.owners.length === 1
                        ? 'Owner'
                        : 'Owners'}:{' '}
                      {organisation.owners.map(shortName).join(', ')}
                    </span>
                  }
                />
                <Chip
                  label={
                    organisation.members === 1
                      ? '1 member'
                      : `${organisation.members} members`
                  }
                  size="small"
                  className={classes.chip}
                />
                <ListItemSecondaryAction>
                  <IconButton
                    edge="end"
                    aria-label={`Remove ${organisation.name}`}
                    onClick={() => handleRemove(organisation)}
                    disabled={removing !== null}
                  >
                    {removing === organisation.slug ? (
                      <CircularProgress size={20} />
                    ) : (
                      <DeleteIcon />
                    )}
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        )}

        <Box mt={2}>
          <Typography variant="caption" color="textSecondary">
            Only portal administrators see this list. Removing an organisation
            frees its name and address, and leaves everyone in it free to create
            an organisation or join another. An organisation's name, address,
            look and members are its owners' to change.
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );
};
