import { useState, useEffect, useCallback } from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  TextField,
  Button,
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
import PersonAddIcon from '@material-ui/icons/PersonAdd';
import GroupIcon from '@material-ui/icons/Group';
import PersonIcon from '@material-ui/icons/Person';
import { useApi, fetchApiRef } from '@backstage/core-plugin-api';

const useStyles = makeStyles(theme => ({
  root: {
    marginBottom: theme.spacing(3),
  },
  addForm: {
    display: 'flex',
    gap: theme.spacing(2),
    alignItems: 'flex-start',
    marginBottom: theme.spacing(2),
  },
  textField: {
    flexGrow: 1,
  },
  list: {
    backgroundColor: theme.palette.background.paper,
  },
  listItem: {
    borderBottom: `1px solid ${theme.palette.divider}`,
  },
  chip: {
    marginRight: theme.spacing(1),
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

interface Admin {
  id: number;
  entity_ref: string;
  type: 'user' | 'group';
  added_at: string;
  added_by: string | null;
}

export const BrandingAdminManagement: React.FC = () => {
  const classes = useStyles();
  const fetchApi = useApi(fetchApiRef);
  const [admins, setAdmins] = useState<Admin[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newAdmin, setNewAdmin] = useState('');
  const [adding, setAdding] = useState(false);
  const [removing, setRemoving] = useState<number | null>(null);

  const fetchAdmins = useCallback(async () => {
    try {
      setError(null);
      const response = await fetchApi.fetch('/api/branding-settings/admins');
      if (!response.ok) {
        if (response.status === 403) {
          setError('You do not have permission to manage admins');
          return;
        }
        throw new Error('Failed to fetch admins');
      }
      const data = await response.json();
      setAdmins(data.admins || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch admins');
    } finally {
      setIsLoading(false);
    }
  }, [fetchApi]);

  useEffect(() => {
    fetchAdmins();
  }, [fetchAdmins]);

  const handleAddAdmin = async () => {
    if (!newAdmin.trim()) return;

    try {
      setAdding(true);
      setError(null);

      const response = await fetchApi.fetch('/api/branding-settings/admins', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ entityRef: newAdmin.trim() }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to add admin');
      }

      const data = await response.json();
      setAdmins(data.admins || []);
      setNewAdmin('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add admin');
    } finally {
      setAdding(false);
    }
  };

  const handleRemoveAdmin = async (id: number) => {
    try {
      setRemoving(id);
      setError(null);

      const response = await fetchApi.fetch(
        `/api/branding-settings/admins/${id}`,
        {
          method: 'DELETE',
        },
      );

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.error || 'Failed to remove admin');
      }

      const data = await response.json();
      setAdmins(data.admins || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to remove admin');
    } finally {
      setRemoving(null);
    }
  };

  const formatEntityRef = (ref: string) => {
    // Extract just the name from user:default/name or group:default/name
    const match = ref.match(/^(user|group):[^/]+\/(.+)$/);
    return match ? match[2] : ref;
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
        title="Branding Administrators"
        subheader="Manage who can modify branding settings"
      />
      <CardContent>
        {error && (
          <Alert severity="error" style={{ marginBottom: 16 }}>
            {error}
          </Alert>
        )}

        {/* Add Admin Form */}
        <Box className={classes.addForm}>
          <TextField
            className={classes.textField}
            label="Add User or Group"
            value={newAdmin}
            onChange={e => setNewAdmin(e.target.value)}
            placeholder="username or group:default/team-name"
            helperText="Enter a username or full entity ref (e.g., user:default/john or group:default/admins)"
            variant="outlined"
            size="small"
            disabled={adding}
            onKeyPress={e => {
              if (e.key === 'Enter') handleAddAdmin();
            }}
          />
          <Button
            variant="contained"
            color="primary"
            startIcon={
              adding ? <CircularProgress size={20} /> : <PersonAddIcon />
            }
            onClick={handleAddAdmin}
            disabled={adding || !newAdmin.trim()}
          >
            Add
          </Button>
        </Box>

        {/* Admins List */}
        {admins.length === 0 ? (
          <Box className={classes.emptyState}>
            <Typography variant="body1">
              No administrators configured yet.
            </Typography>
            <Typography variant="body2">
              Add a user or group above to get started.
            </Typography>
          </Box>
        ) : (
          <List className={classes.list}>
            {admins.map(admin => (
              <ListItem key={admin.id} className={classes.listItem}>
                <Chip
                  icon={admin.type === 'group' ? <GroupIcon /> : <PersonIcon />}
                  label={admin.type}
                  size="small"
                  className={classes.chip}
                  color={admin.type === 'group' ? 'primary' : 'default'}
                />
                <ListItemText
                  primary={formatEntityRef(admin.entity_ref)}
                  secondary={
                    <span className={classes.metadata}>
                      {admin.entity_ref}
                      {admin.added_by && ` - Added by ${admin.added_by}`}
                    </span>
                  }
                />
                <ListItemSecondaryAction>
                  <IconButton
                    edge="end"
                    aria-label="delete"
                    onClick={() => handleRemoveAdmin(admin.id)}
                    disabled={removing === admin.id}
                  >
                    {removing === admin.id ? (
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
            Users listed here can upload logos, change the organization name,
            and manage other admins. Groups allow all members to have admin
            access (requires catalog integration).
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );
};

export default BrandingAdminManagement;
