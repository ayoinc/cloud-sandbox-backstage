import { useCallback, useEffect, useState } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  Chip,
  CircularProgress,
  IconButton,
  List,
  ListItem,
  ListItemSecondaryAction,
  ListItemText,
  MenuItem,
  TextField,
  Typography,
} from '@material-ui/core';
import { Alert } from '@material-ui/lab';
import DeleteIcon from '@material-ui/icons/Delete';
import PersonAddIcon from '@material-ui/icons/PersonAdd';
import { fetchApiRef, useApi } from '@backstage/core-plugin-api';
import { organisationPath } from '@internal/brand';
import {
  ORGANISATIONS_API,
  answer,
  shortName,
  useOrganisation,
} from './OrganisationContext';
import type { Role } from './OrganisationContext';

interface People {
  members: {
    userEntityRef: string;
    role: Role;
    addedBy: string;
  }[];
  /** Asked to join, and not answered yet. */
  invitations: {
    userEntityRef: string;
    role: Role;
    invitedBy: string;
  }[];
}

const roleName = (role: Role) => (role === 'owner' ? 'Owner' : 'Member');

/**
 * Who belongs to the organisation and who has been asked to join. Members
 * land at its address when they sign in; owners can also change its name,
 * look and this list. Nobody is added without agreeing: an owner invites,
 * and the person joins from their own Organisation tab.
 */
export const OrganisationMembers = () => {
  const fetchApi = useApi(fetchApiRef);
  const { organisation, role, userEntityRef } = useOrganisation();
  const [people, setPeople] = useState<People | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [newRole, setNewRole] = useState<Role>('member');
  const [busy, setBusy] = useState(false);
  // The page that shows this card has checked that there is one.
  const { slug, name: organisationName } = organisation!;
  const api = `${ORGANISATIONS_API}/${slug}/members`;

  /** Runs a call, then shows the list as it is afterwards. */
  const run = useCallback(
    async (call?: () => Promise<Response>) => {
      setBusy(true);
      setError(null);
      try {
        if (call) {
          await answer<unknown>(await call(), 'Failed to update the members');
        }
        setPeople(
          await answer<People>(
            await fetchApi.fetch(api),
            'Failed to load the members',
          ),
        );
        return true;
      } catch (caught) {
        setError(caught instanceof Error ? caught.message : String(caught));
        return false;
      } finally {
        setBusy(false);
      }
    },
    [api, fetchApi],
  );

  useEffect(() => {
    run();
  }, [run]);

  const invite = async () => {
    const invited = await run(() =>
      fetchApi.fetch(api, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ entityRef: name.trim(), role: newRole }),
      }),
    );
    if (invited) {
      setName('');
      setNewRole('member');
    }
  };

  /** Removes a member or takes back an invitation, once confirmed. */
  const remove = async (person: string, question: string) => {
    // eslint-disable-next-line no-alert
    if (!window.confirm(question)) {
      return;
    }
    const call = () =>
      fetchApi.fetch(`${api}/${encodeURIComponent(person)}`, {
        method: 'DELETE',
      });
    if (person !== userEntityRef) {
      await run(call);
      return;
    }
    // Leaving: the list is no longer ours to read.
    setBusy(true);
    setError(null);
    try {
      await answer<void>(await call(), 'Failed to leave the organisation');
      // No longer a member: carry on outside any organisation.
      window.location.assign(organisationPath(null));
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : String(caught));
      setBusy(false);
    }
  };

  const isOwner = role === 'owner';
  return (
    <Card>
      <CardHeader
        title="Members"
        subheader="People who land at this organisation's address when they sign in"
      />
      <CardContent>
        {error && (
          <Alert severity="error" style={{ marginBottom: 16 }}>
            {error}
          </Alert>
        )}
        {isOwner && (
          <Box mb={2}>
            <TextField
              fullWidth
              label="Invite a person"
              value={name}
              onChange={e => setName(e.target.value)}
              placeholder="jane or jane@example.com"
              helperText="Their GitHub login if they sign in with GitHub, or their full email address if they sign in with Google. They are asked to join when they next open the portal. Someone already in another organisation has to leave it first; you are not told whether they are. What you type is not checked: a mistyped login or address invites nobody."
              variant="outlined"
              size="small"
              disabled={busy}
              onKeyDown={e => {
                if (e.key === 'Enter' && name.trim()) {
                  invite();
                }
              }}
            />
            <Box display="flex" mt={2} style={{ gap: 16 }}>
              <TextField
                select
                label="Role"
                value={newRole}
                onChange={e =>
                  setNewRole(e.target.value === 'owner' ? 'owner' : 'member')
                }
                variant="outlined"
                size="small"
                disabled={busy}
                style={{ minWidth: 140 }}
              >
                <MenuItem value="member">Member</MenuItem>
                <MenuItem value="owner">Owner</MenuItem>
              </TextField>
              <Button
                variant="contained"
                color="primary"
                startIcon={<PersonAddIcon />}
                onClick={invite}
                disabled={busy || !name.trim()}
              >
                Invite
              </Button>
            </Box>
          </Box>
        )}
        {people === null && !error && (
          <Box display="flex" justifyContent="center" p={3}>
            <CircularProgress />
          </Box>
        )}
        <List disablePadding>
          {people?.members.map(member => {
            const self = member.userEntityRef === userEntityRef;
            const who = shortName(member.userEntityRef);
            return (
              <ListItem key={member.userEntityRef} divider>
                <ListItemText
                  primary={who}
                  secondary={
                    member.addedBy === member.userEntityRef
                      ? 'Created the organisation'
                      : `Invited by ${shortName(member.addedBy)}`
                  }
                />
                <Chip
                  size="small"
                  label={roleName(member.role)}
                  color={member.role === 'owner' ? 'primary' : 'default'}
                />
                {(isOwner || self) && (
                  <ListItemSecondaryAction>
                    <IconButton
                      edge="end"
                      aria-label={
                        self ? 'Leave the organisation' : `Remove ${who}`
                      }
                      disabled={busy}
                      onClick={() =>
                        remove(
                          member.userEntityRef,
                          self
                            ? `Leave ${organisationName}? You will no longer land at its address, and can then create an organisation or join another.`
                            : `Remove ${who} from ${organisationName}? They will no longer land at this address.`,
                        )
                      }
                    >
                      <DeleteIcon />
                    </IconButton>
                  </ListItemSecondaryAction>
                )}
              </ListItem>
            );
          })}
          {people?.invitations.map(invitation => {
            const who = shortName(invitation.userEntityRef);
            return (
              <ListItem key={invitation.userEntityRef} divider>
                <ListItemText
                  primary={who}
                  secondary={`Invited by ${shortName(
                    invitation.invitedBy,
                  )} as ${roleName(
                    invitation.role,
                  ).toLowerCase()}, has not joined yet`}
                />
                <Chip size="small" variant="outlined" label="Invited" />
                {isOwner && (
                  <ListItemSecondaryAction>
                    <IconButton
                      edge="end"
                      aria-label={`Take back the invitation to ${who}`}
                      disabled={busy}
                      onClick={() =>
                        remove(
                          invitation.userEntityRef,
                          `Take back the invitation to ${who}?`,
                        )
                      }
                    >
                      <DeleteIcon />
                    </IconButton>
                  </ListItemSecondaryAction>
                )}
              </ListItem>
            );
          })}
        </List>
        <Box mt={2}>
          <Typography variant="caption" color="textSecondary">
            {isOwner
              ? 'Owners can change the name, logo, theme and this list. An organisation keeps at least one owner: before you leave, invite another owner and wait until they have joined.'
              : 'Only an owner can invite or remove people. You can leave.'}
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );
};
