import { useState } from 'react';
import { Progress } from '@backstage/core-components';
import {
  Box,
  Button,
  Card,
  CardActions,
  CardContent,
  CardHeader,
  Grid,
  Typography,
} from '@material-ui/core';
import { Alert } from '@material-ui/lab';
import { organisationPath } from '@internal/brand';
import { CreateOrganisation } from './CreateOrganisation';
import { OrganisationMembers } from './OrganisationMembers';
import {
  OrganisationProvider,
  shortName,
  useOrganisation,
} from './OrganisationContext';
import type { ReceivedInvitation } from './OrganisationContext';
import { OrganisationSettingsPanel } from './OrganisationSettingsPanel';
import { SignInMethods } from './SignInMethods';

/**
 * An organisation that has asked the user to join, with the two answers.
 * Someone who already has an organisation (`current`) can only decline
 * until they leave it.
 */
const InvitationCard = (props: {
  invitation: ReceivedInvitation;
  current?: string;
}) => {
  const { invitation, current } = props;
  const { join, decline } = useOrganisation();
  const [busy, setBusy] = useState(false);

  const answerWith = async (accept: boolean) => {
    setBusy(true);
    try {
      if (accept) {
        await join(invitation.slug);
        // A full load: the app has to start again under the new address.
        window.location.assign(organisationPath(invitation.slug));
        return;
      }
      await decline(invitation.slug);
    } catch {
      // Shown by the page.
    }
    setBusy(false);
  };

  return (
    <Card>
      <CardHeader
        title={`Join ${invitation.name}?`}
        subheader={`${shortName(invitation.invitedBy)} has invited you as ${
          invitation.role === 'owner'
            ? 'an owner. Owners can change its name, logo and theme and invite people'
            : 'a member. Members can see who is in it and can leave'
        }.`}
      />
      <CardContent>
        <Typography variant="body2">
          {current
            ? `You can belong to only one organisation at a time. To join ${invitation.name}, leave ${current} first: remove yourself under Members.`
            : `Joining takes you to ${invitation.name}'s address, ${
                window.location.origin
              }${organisationPath(
                invitation.slug,
              )}, now and every time you sign in. You can belong to only one organisation at a time, and can leave it again.`}
        </Typography>
      </CardContent>
      <CardActions>
        <Button
          variant="contained"
          color="primary"
          disabled={busy || Boolean(current)}
          onClick={() => answerWith(true)}
        >
          Join {invitation.name}
        </Button>
        <Button disabled={busy} onClick={() => answerWith(false)}>
          Decline
        </Button>
      </CardActions>
    </Card>
  );
};

const Controls = () => {
  const { organisation, canCreate, invitations, isLoading, error } =
    useOrganisation();
  if (isLoading) {
    return <Progress />;
  }
  if (organisation) {
    return (
      <Grid container spacing={3}>
        {invitations.map(invitation => (
          <Grid item xs={12} md={8} key={invitation.slug}>
            <InvitationCard
              invitation={invitation}
              current={organisation.name}
            />
          </Grid>
        ))}
        <Grid item xs={12} md={8}>
          <OrganisationSettingsPanel />
        </Grid>
        <Grid item xs={12} md={4}>
          <OrganisationMembers />
          <Box mt={3}>
            <SignInMethods />
          </Box>
        </Grid>
      </Grid>
    );
  }
  return (
    <Grid container spacing={3}>
      <Grid item xs={12} md={8}>
        {/* The create form shows the error beside its fields. */}
        {error && !canCreate && (
          <Box mb={3}>
            <Alert severity="error">{error}</Alert>
          </Box>
        )}
        {invitations.map(invitation => (
          <Box mb={3} key={invitation.slug}>
            <InvitationCard invitation={invitation} />
          </Box>
        ))}
        {canCreate && <CreateOrganisation />}
        {!canCreate && !error && (
          <Alert severity="info">
            Guest sign-in is shared by everyone who uses it, so it cannot have
            an organisation. Sign in with your own account to create one.
          </Alert>
        )}
      </Grid>
      <Grid item xs={12} md={4}>
        <SignInMethods />
      </Grid>
    </Grid>
  );
};

/**
 * The signed-in user's organisation: its name, address, look and members;
 * or, for someone without one, the form that creates one. Either way, the
 * invitations waiting for them. Shown as the Organisation tab of Settings.
 */
export const OrganisationControls = () => (
  <OrganisationProvider>
    <Controls />
  </OrganisationProvider>
);
