import { useCallback, useEffect, useState } from 'react';
import type { ComponentType } from 'react';
import {
  Progress,
  ProxiedSignInPage,
  UserIdentity,
} from '@backstage/core-components';
import {
  discoveryApiRef,
  errorApiRef,
  githubAuthApiRef,
  googleAuthApiRef,
  useAnalytics,
  useApi,
  useApiHolder,
} from '@backstage/core-plugin-api';
import type {
  ApiRef,
  BackstageIdentityApi,
  IdentityApi,
  ProfileInfoApi,
  SessionApi,
} from '@backstage/core-plugin-api';
import CircularProgress from '@material-ui/core/CircularProgress';
import SvgIcon from '@material-ui/core/SvgIcon';
import type { SvgIconProps } from '@material-ui/core/SvgIcon';
import { makeStyles } from '@material-ui/core/styles';
import type { Theme } from '@material-ui/core/styles';
import GitHubIcon from '@material-ui/icons/GitHub';
import PersonOutlineIcon from '@material-ui/icons/PersonOutline';
import { activeBrand } from './activeBrand';

/**
 * Where Backstage's own sign-in page remembers which way someone signed in,
 * so that they are signed in again without asking. The same key is used
 * here: a choice remembered by that page still holds.
 */
const REMEMBERED_KEY = '@backstage/core:SignInPage:provider';

/** Google's "G", in its own colours whatever the theme. */
function GoogleIcon(props: SvgIconProps) {
  return (
    <SvgIcon {...props} viewBox="0 0 48 48">
      <path
        fill="#EA4335"
        d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
      />
      <path
        fill="#4285F4"
        d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
      />
      <path
        fill="#FBBC05"
        d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
      />
      <path
        fill="#34A853"
        d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
      />
    </SvgIcon>
  );
}

/** One way of signing in, as a button. */
export interface SignInChoice {
  /** As Backstage's sign-in page names it, which is what is remembered. */
  id: string;
  /** The key under `auth.providers` that turns this choice on. */
  provider: string;
  /** What the button says. */
  label: string;
  Icon: ComponentType<SvgIconProps>;
  /** The account provider's API. Guest sign-in has none. */
  apiRef?: ApiRef<ProfileInfoApi & BackstageIdentityApi & SessionApi>;
}

/**
 * Every way of signing in the portal can offer: GitHub, Google and guest
 * access. The app shows the ones its `auth.providers` config lists.
 */
export const brandSignInProviders: SignInChoice[] = [
  {
    id: 'github-auth-provider',
    provider: 'github',
    label: 'Continue with GitHub',
    Icon: GitHubIcon,
    apiRef: githubAuthApiRef,
  },
  {
    id: 'google-auth-provider',
    provider: 'google',
    label: 'Continue with Google',
    Icon: GoogleIcon,
    apiRef: googleAuthApiRef,
  },
  {
    id: 'guest',
    provider: 'guest',
    label: 'Continue as guest',
    Icon: PersonOutlineIcon,
  },
];

const useStyles = makeStyles((theme: Theme) => {
  const { mode, tokens, c } = activeBrand(theme);
  const { shape, spacing, target, typography, focus } = tokens;
  return {
    list: {
      listStyle: 'none',
      margin: 0,
      padding: 0,
      display: 'flex',
      flexDirection: 'column',
      gap: spacing[3],
    },
    choice: {
      display: 'flex',
      alignItems: 'center',
      gap: spacing[3],
      width: '100%',
      minHeight: target.minimum + 4,
      padding: `0 ${spacing[5]}px`,
      border: `1px solid ${c.outline}`,
      borderRadius: shape.control,
      backgroundColor:
        mode === 'dark' ? c.surfaceContainer : c.surfaceContainerLowest,
      color: c.onSurface,
      font: 'inherit',
      fontSize: `${typography.size.body / 16}rem`,
      fontWeight: typography.weight.bold,
      textAlign: 'left',
      cursor: 'pointer',
      transition: 'background-color 120ms, border-color 120ms',
      '&:hover:not(:disabled)': {
        borderColor: c.onSurface,
        backgroundColor:
          mode === 'dark' ? c.surfaceContainerHigh : c.surfaceContainerLow,
      },
      '&:focus-visible': {
        outline: `${focus.width}px solid ${focus.color}`,
        outlineOffset: 0,
        boxShadow: `0 0 0 ${focus.width * 2}px ${focus.edge}`,
      },
      '&:disabled': { cursor: 'default', opacity: 0.6 },
    },
    label: { flex: 1 },
    back: {
      marginTop: spacing[4],
      padding: 0,
      border: 0,
      background: 'none',
      color: c.link.default,
      font: 'inherit',
      textDecoration: 'underline',
      cursor: 'pointer',
    },
    problem: { margin: 0, color: c.onSurface },
  };
});

export interface SignInChoicesProps {
  providers: SignInChoice[];
  /** Hands the app whoever signed in. Called once. */
  onSignInSuccess(identityApi: IdentityApi): void;
}

/**
 * The ways of signing in, one button each. Does what Backstage's own
 * sign-in page does behind its cards: signs back in whoever is remembered,
 * opens the provider's window on a click, remembers the choice, forgets it
 * on sign-out or failure, and reports sign-in and sign-out to analytics.
 */
export function SignInChoices(props: SignInChoicesProps) {
  const { providers, onSignInSuccess } = props;
  const classes = useStyles();
  const apis = useApiHolder();
  const errorApi = useApi(errorApiRef);
  const discoveryApi = useApi(discoveryApiRef);
  const analytics = useAnalytics();
  // `checking` while a remembered choice is tried; `guest` while the guest
  // account is being signed in, which Backstage's own component does.
  const [stage, setStage] = useState<'checking' | 'choosing' | 'guest'>(
    'checking',
  );
  const [busy, setBusy] = useState<string | null>(null);

  const finish = useCallback(
    (identityApi: IdentityApi, endSession?: () => Promise<unknown>) => {
      onSignInSuccess({
        getProfileInfo: () => identityApi.getProfileInfo(),
        getBackstageIdentity: () => identityApi.getBackstageIdentity(),
        getCredentials: () => identityApi.getCredentials(),
        signOut: async () => {
          window.localStorage.removeItem(REMEMBERED_KEY);
          await endSession?.();
          await identityApi.signOut();
          analytics.captureEvent('signOut', 'success');
        },
      });
      analytics.captureEvent('signIn', 'success');
    },
    [analytics, onSignInSuccess],
  );

  /**
   * Backstage's guest identity forgets itself on sign-out but does not tell
   * the backend, which would keep the guest's session cookie. This does.
   */
  const finishGuest = useCallback(
    (identityApi: IdentityApi) =>
      finish(identityApi, async () =>
        fetch(`${await discoveryApi.getBaseUrl('auth')}/guest/logout`, {
          method: 'POST',
          headers: { 'x-requested-with': 'XMLHttpRequest' },
          credentials: 'include',
        }).catch(() => {
          // Signed out here all the same; the cookie runs out by itself.
        }),
      ),
    [discoveryApi, finish],
  );

  /** Tells the user that signing in did not work, and why. */
  const report = useCallback(
    (error: unknown) => {
      const reason = error instanceof Error ? error.message : String(error);
      errorApi.post(
        new Error(
          `Could not sign you in. Try again, or choose another way. (${reason})`,
        ),
      );
    },
    [errorApi],
  );

  /** A choice that did not sign in is not tried again by itself. */
  const fail = useCallback(
    (error: unknown) => {
      window.localStorage.removeItem(REMEMBERED_KEY);
      report(error);
    },
    [report],
  );

  /** Whoever the provider says is signed in, or nobody. */
  const identityFrom = useCallback(
    async (choice: SignInChoice, ask: boolean) => {
      const authApi = choice.apiRef && apis.get(choice.apiRef);
      const identity = await authApi?.getBackstageIdentity(
        ask ? { instantPopup: true } : { optional: true },
      );
      if (!authApi || !identity) {
        return undefined;
      }
      return UserIdentity.create({
        identity: identity.identity,
        profile: await authApi.getProfile(),
        authApi,
      });
    },
    [apis],
  );

  // Once, when the page opens: a failed sign-in reported in the address,
  // then whoever is remembered.
  useEffect(() => {
    const reported = new URLSearchParams(window.location.search).get('error');
    if (reported) {
      report(reported);
    }
    const remembered = providers.find(
      choice => choice.id === window.localStorage.getItem(REMEMBERED_KEY),
    );
    if (!remembered) {
      setStage('choosing');
      return undefined;
    }
    if (!remembered.apiRef) {
      setStage('guest');
      return undefined;
    }
    let live = true;
    identityFrom(remembered, false)
      .then(identityApi => {
        if (!live) {
          return;
        }
        if (identityApi) {
          finish(identityApi);
        } else {
          setStage('choosing');
        }
      })
      .catch(error => {
        if (live) {
          fail(error);
          setStage('choosing');
        }
      });
    return () => {
      live = false;
    };
    // The list of providers is fixed for the life of the page.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const signIn = async (choice: SignInChoice) => {
    window.localStorage.setItem(REMEMBERED_KEY, choice.id);
    if (!choice.apiRef) {
      setStage('guest');
      return;
    }
    setBusy(choice.id);
    try {
      const identityApi = await identityFrom(choice, true);
      if (!identityApi) {
        throw new Error('This portal is not set up for that way of signing in');
      }
      finish(identityApi);
    } catch (error) {
      fail(error);
      setBusy(null);
    }
  };

  // Shown by Backstage's component when the guest account cannot sign in.
  // The choice is forgotten at once, so that a reload does not try it again.
  const GuestUnavailable = useCallback(
    ({ error }: { error?: Error }) => {
      window.localStorage.removeItem(REMEMBERED_KEY);
      return (
        <div role="alert">
          <p className={classes.problem}>
            Guest sign-in did not work.{error ? ` ${error.message}` : ''}
          </p>
          <button
            type="button"
            className={classes.back}
            onClick={() => setStage('choosing')}
          >
            Choose another way to sign in
          </button>
        </div>
      );
    },
    [classes],
  );

  if (stage === 'checking') {
    return <Progress />;
  }
  if (stage === 'guest') {
    return (
      <ProxiedSignInPage
        provider="guest"
        onSignInSuccess={finishGuest}
        ErrorComponent={GuestUnavailable}
      />
    );
  }
  return (
    <ul className={classes.list}>
      {providers.map(choice => (
        <li key={choice.id}>
          <button
            type="button"
            className={classes.choice}
            disabled={busy !== null}
            onClick={() => signIn(choice)}
          >
            <choice.Icon aria-hidden="true" />
            <span className={classes.label}>{choice.label}</span>
            {busy === choice.id ? (
              <CircularProgress size={18} color="inherit" />
            ) : null}
          </button>
        </li>
      ))}
    </ul>
  );
}
