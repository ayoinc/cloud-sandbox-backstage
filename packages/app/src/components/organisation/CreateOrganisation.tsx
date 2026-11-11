import { useState } from 'react';
import type { FormEvent } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  TextField,
} from '@material-ui/core';
import { Alert } from '@material-ui/lab';
import { organisationPath } from '@internal/brand';
import { useOrganisation } from './OrganisationContext';

// The backend's rule (rules.ts), repeated here so the form can say what is
// wrong before anything is sent.
export const ADDRESS = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;
export const ADDRESS_RULE =
  '3 to 40 lower-case letters, digits and dashes, starting and ending with a letter or digit';

/** "Acme Ltd." gives acme-ltd. */
const addressFor = (name: string) =>
  name
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 40)
    .replace(/-+$/, '');

/**
 * Creates the signed-in user's organisation: a name and the address it will
 * live at. Whoever creates it owns it, and from then on signs in to it.
 */
export const CreateOrganisation = () => {
  const { create, error } = useOrganisation();
  const [name, setName] = useState('');
  // Follows the name until the address is typed in by hand.
  const [typedAddress, setTypedAddress] = useState<string | null>(null);
  const [creating, setCreating] = useState(false);
  const address = typedAddress ?? addressFor(name);
  const problem = ADDRESS.test(address) ? null : ADDRESS_RULE;

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setCreating(true);
    try {
      const organisation = await create(name.trim(), address);
      // A full load: the app has to start again under the new address.
      window.location.assign(
        organisationPath(organisation.slug, '/settings/organisation'),
      );
    } catch {
      // Shown through `error`.
      setCreating(false);
    }
  };

  return (
    <Card>
      <CardHeader
        title="Create your organisation"
        subheader="An organisation has a name, a logo and a theme, shown only at its own address. Anyone who opens that address sees them; the people who join land there when they sign in. You can belong to one organisation"
      />
      <CardContent>
        {error && (
          <Alert severity="error" style={{ marginBottom: 16 }}>
            {error}
          </Alert>
        )}
        <form onSubmit={submit}>
          <TextField
            fullWidth
            required
            label="Organisation name"
            value={name}
            onChange={e => setName(e.target.value)}
            placeholder="Acme Ltd"
            variant="outlined"
            disabled={creating}
            inputProps={{ maxLength: 80 }}
          />
          <Box mt={2}>
            <TextField
              fullWidth
              required
              label="Address"
              value={address}
              onChange={e => setTypedAddress(e.target.value.toLowerCase())}
              error={address !== '' && problem !== null}
              helperText={
                (address !== '' && problem) ||
                `${window.location.origin}${organisationPath(
                  address || 'your-address',
                )}. An owner can change it later`
              }
              variant="outlined"
              disabled={creating}
              inputProps={{ maxLength: 40, spellCheck: false }}
            />
          </Box>
          <Box mt={3}>
            <Button
              type="submit"
              variant="contained"
              color="primary"
              disabled={creating || !name.trim() || problem !== null}
            >
              {creating ? 'Creating...' : 'Create organisation'}
            </Button>
          </Box>
        </form>
      </CardContent>
    </Card>
  );
};
