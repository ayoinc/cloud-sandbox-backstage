import { useCallback, useEffect, useState } from 'react';
import {
  configApiRef,
  discoveryApiRef,
  fetchApiRef,
  useApi,
} from '@backstage/core-plugin-api';
import {
  Box,
  Button,
  Card,
  CardContent,
  CardHeader,
  IconButton,
  List,
  ListItem,
  ListItemSecondaryAction,
  ListItemText,
  Typography,
} from '@material-ui/core';
import { Alert } from '@material-ui/lab';
import DeleteIcon from '@material-ui/icons/Delete';
import { answer } from './OrganisationContext';

const ACCOUNT_LINKS_API = 'plugin://account-links';

const PROVIDER_NAMES: Record<string, string> = {
  github: 'GitHub',
  google: 'Google',
};

interface Link {
  provider: string;
  id: string;
  linkedAt: string;
}

/**
 * The other sign-in methods that sign in as this account. Someone who
 * created their organisation signed in with GitHub links their Google
 * account here, and from then on Google signs them in as the same account:
 * the same organisation and look, files and settings. Shown only where the
 * portal offers more than one sign-in method and can link them.
 */
export const SignInMethods = () => {
  const fetchApi = useApi(fetchApiRef);
  const discoveryApi = useApi(discoveryApiRef);
  const configApi = useApi(configApiRef);
  const [links, setLinks] = useState<Link[] | null>(null);
  const [unavailable, setUnavailable] = useState(false);
  const [message, setMessage] = useState<{
    severity: 'success' | 'error';
    text: string;
  } | null>(null);
  const [busy, setBusy] = useState(false);

  const offered = (
    configApi.getOptionalConfig('auth.providers')?.keys() ?? []
  ).filter(provider => provider in PROVIDER_NAMES);

  const load = useCallback(async () => {
    const response = await fetchApi.fetch(ACCOUNT_LINKS_API);
    if (response.status === 404) {
      // This backend does not link sign-in methods.
      setUnavailable(true);
      return;
    }
    const body = await answer<{ links: Link[] }>(
      response,
      'Failed to load your sign-in methods',
    );
    setLinks(body.links);
  }, [fetchApi]);

  useEffect(() => {
    load().catch(error =>
      setMessage({ severity: 'error', text: error.message }),
    );
  }, [load]);

  const link = async (provider: string) => {
    // Opened now, while the click still counts: a window opened after
    // waiting for the network is blocked by some browsers. It is pointed at
    // the provider once the link intent is set.
    const popup = window.open(
      'about:blank',
      'portal-account-link',
      'width=500,height=700',
    );
    setBusy(true);
    setMessage(null);
    try {
      if (!popup) {
        throw new Error(
          'The browser blocked the sign-in window. Allow pop-ups for this site and try again',
        );
      }
      await answer<void>(
        await fetchApi.fetch(`${ACCOUNT_LINKS_API}/${provider}/intent`, {
          method: 'POST',
        }),
        'Could not start linking',
      );
      const authBase = await discoveryApi.getBaseUrl('auth');
      const start = new URL(`${authBase}/${provider}/start`);
      start.search = new URLSearchParams({
        env: 'production',
        origin: window.location.origin,
        flow: 'popup',
        scope: '',
      }).toString();
      popup.location.href = start.toString();
      const result = await new Promise<{ ok: boolean; text: string }>(
        resolve => {
          const timer = window.setInterval(() => {
            if (popup.closed) {
              finish({ ok: false, text: '' });
            }
          }, 500);
          const onMessage = (event: MessageEvent) => {
            if (event.origin !== window.location.origin) {
              return;
            }
            const data = event.data;
            if (data?.type === 'portal-account-link') {
              finish({
                ok: true,
                text: `${PROVIDER_NAMES[provider]} account ${data.linked.id} now signs in as this account.`,
              });
            } else if (data?.type === 'authorization_response') {
              finish({
                ok: false,
                text: data.error
                  ? data.error.message
                  : 'That window signed in instead of linking. Try again',
              });
            }
          };
          function finish(value: { ok: boolean; text: string }) {
            window.clearInterval(timer);
            window.removeEventListener('message', onMessage);
            resolve(value);
          }
          window.addEventListener('message', onMessage);
        },
      );
      if (result.text) {
        setMessage({
          severity: result.ok ? 'success' : 'error',
          text: result.text,
        });
      }
      await load();
    } catch (error) {
      popup?.close();
      setMessage({ severity: 'error', text: (error as Error).message });
    } finally {
      setBusy(false);
    }
  };

  const unlink = async (item: Link) => {
    setBusy(true);
    setMessage(null);
    try {
      await answer<void>(
        await fetchApi.fetch(
          `${ACCOUNT_LINKS_API}/${item.provider}/${encodeURIComponent(
            item.id,
          )}`,
          { method: 'DELETE' },
        ),
        'Could not unlink',
      );
      await load();
    } catch (error) {
      setMessage({ severity: 'error', text: (error as Error).message });
    } finally {
      setBusy(false);
    }
  };

  if (unavailable || offered.length < 2) {
    return null;
  }

  return (
    <Card>
      <CardHeader title="Sign-in methods" />
      <CardContent>
        <Typography variant="body2" paragraph>
          Link your other sign-in method to this account, and either one signs
          you in as the same person: the same organisation and look, files and
          settings. Without a link, each one is a separate account.
        </Typography>
        {message && (
          <Box mb={2}>
            <Alert severity={message.severity}>{message.text}</Alert>
          </Box>
        )}
        {links && links.length > 0 && (
          <List dense>
            {links.map(item => (
              <ListItem key={`${item.provider}:${item.id}`}>
                <ListItemText
                  primary={`${
                    PROVIDER_NAMES[item.provider] ?? item.provider
                  }: ${item.id}`}
                  secondary={`Linked ${new Date(
                    item.linkedAt,
                  ).toLocaleDateString()}`}
                />
                <ListItemSecondaryAction>
                  <IconButton
                    edge="end"
                    aria-label={`Unlink ${item.id}`}
                    disabled={busy}
                    onClick={() => unlink(item)}
                  >
                    <DeleteIcon />
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        )}
        <Box display="flex" style={{ gap: 8 }} flexWrap="wrap">
          {offered.map(provider => (
            <Button
              key={provider}
              variant="outlined"
              disabled={busy}
              onClick={() => link(provider)}
            >
              Link a {PROVIDER_NAMES[provider]} account
            </Button>
          ))}
        </Box>
      </CardContent>
    </Card>
  );
};
