import { Suspense, lazy, useCallback } from 'react';
import type { ComponentProps } from 'react';
import { SignInPage } from '@backstage/core-components';
import type {
  BackstageOverrides,
  IdentityProviders,
} from '@backstage/core-components';
import { githubAuthApiRef, googleAuthApiRef } from '@backstage/core-plugin-api';
import { ThemeProvider, makeStyles, useTheme } from '@material-ui/core/styles';
import type { Theme } from '@material-ui/core/styles';
import useMediaQuery from '@material-ui/core/useMediaQuery';
import { LogoFull } from '../logo/Logo';
import { brandTokens } from '../tokens/brandTokens';
import type { BrandMode } from '../tokens/brandTokens';

// Dynamic import: the demo is decorative, so the sign-in page's first paint must not wait for its code.
const CatalogSearchDemo = lazy(() => import('../stageshow/CatalogSearchDemo'));

/**
 * Props for {@link BrandedSignInPage}: exactly the props of the core
 * `SignInPage` from `@backstage/core-components` (either `providers` for the
 * multi-provider page, or `provider` plus optional `auto` for a single one).
 */
export type BrandedSignInPageProps = ComponentProps<typeof SignInPage>;

/**
 * Every sign-in provider the portal can offer: GitHub, Google and guest
 * access. The app shows the ones its `auth.providers` config lists.
 */
export const brandSignInProviders: IdentityProviders = [
  {
    id: 'github-auth-provider',
    title: 'GitHub',
    message: 'Sign in with your GitHub account.',
    apiRef: githubAuthApiRef,
  },
  {
    id: 'google-auth-provider',
    title: 'Google',
    message: 'Sign in with your Google account.',
    apiRef: googleAuthApiRef,
  },
  'guest',
];

const useStyles = makeStyles(theme => {
  const mode: BrandMode = theme.palette.type === 'dark' ? 'dark' : 'light';
  const c = brandTokens.color[mode];
  const { typography, spacing } = brandTokens;
  return {
    root: {
      minHeight: '100vh',
      display: 'grid',
      gridTemplateColumns: 'minmax(0, 1fr)',
      backgroundColor: mode === 'dark' ? c.surface : c.surfaceContainerLow,
      color: c.onSurface,
      fontFamily: typography.fontFamily,
      [theme.breakpoints.up('md')]: {
        gridTemplateColumns: 'minmax(320px, 5fr) 7fr',
      },
    },
    brand: {
      backgroundColor: c.navigation.background,
      color: brandTokens.identity.white,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'space-between',
      gap: spacing[8],
      padding: `${spacing[8]}px ${spacing[6]}px`,
      [theme.breakpoints.up('md')]: {
        padding: `${spacing[15]}px ${spacing[12]}px`,
        minHeight: '100vh',
        position: 'sticky',
        top: 0,
      },
    },
    identity: {
      display: 'flex',
      flexDirection: 'column',
      gap: spacing[3],
      maxWidth: 440,
    },
    // The slot the product demo fills: the panel's free space, from the text
    // column to the panel's right edge. Collapsed with the panel below `md`.
    demo: {
      display: 'none',
      [theme.breakpoints.up('md')]: {
        display: 'block',
        position: 'relative',
        flex: '1 1 0',
        minHeight: 0,
        marginRight: -spacing[12],
      },
    },
    product: {
      margin: 0,
      fontSize: `${typography.size.h2 / 16}rem`,
      lineHeight: typography.lineHeight.tight,
      fontWeight: typography.weight.bold,
    },
    descriptor: {
      margin: 0,
      fontSize: `${typography.size.lead / 16}rem`,
      lineHeight: typography.lineHeight.body,
      color: c.navigation.text,
    },
    rule: {
      width: 64,
      height: 4,
      border: 0,
      margin: `${spacing[2]}px 0`,
      backgroundColor: c.header.accent,
    },
    summary: {
      margin: 0,
      fontSize: `${typography.size.body / 16}rem`,
      lineHeight: typography.lineHeight.body,
      color: c.navigation.text,
    },
    owner: {
      margin: 0,
      fontSize: `${typography.size.sm / 16}rem`,
      color: c.navigation.text,
    },
    panel: {
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'center',
      padding: `${spacing[10]}px ${spacing[4]}px`,
      [theme.breakpoints.up('md')]: {
        alignItems: 'center',
        padding: `${spacing[15]}px ${spacing[12]}px`,
      },
    },
    column: {
      width: '100%',
      maxWidth: 520,
    },
    heading: {
      margin: `0 0 ${spacing[4]}px`,
      fontSize: `${typography.size.h1 / 16}rem`,
      lineHeight: typography.lineHeight.tight,
      fontWeight: typography.weight.bold,
      color: c.onSurface,
    },
    lead: {
      margin: `0 0 ${spacing[6]}px`,
      fontSize: `${typography.size.lead / 16}rem`,
      lineHeight: typography.lineHeight.body,
      color: c.onSurfaceVariant,
    },
    help: {
      margin: `${spacing[8]}px 0 0`,
      paddingTop: spacing[4],
      borderTop: `1px solid ${c.outlineVariant}`,
      fontSize: `${typography.size.body / 16}rem`,
      lineHeight: typography.lineHeight.body,
      color: c.onSurfaceVariant,
      '& a': { color: c.link.default },
    },
  };
});

/**
 * Style overrides applied only inside the sign-in panel. They restyle the core
 * SignInPage output (page chrome, provider cards and buttons) so the provider
 * logic, analytics and error handling stay exactly as Backstage ships them.
 */
function signInOverrides(outer: Theme): BackstageOverrides {
  const mode: BrandMode = outer.palette.type === 'dark' ? 'dark' : 'light';
  const c = brandTokens.color[mode];
  const { shape, spacing, target, typography } = brandTokens;
  return {
    BackstagePage: {
      root: {
        display: 'block',
        height: 'auto',
        minHeight: 0,
        overflowY: 'visible',
        [outer.breakpoints.down('xs')]: { height: 'auto' },
      },
    },
    BackstageHeader: {
      header: { display: 'none' },
    },
    BackstageContent: {
      root: {
        paddingTop: 0,
        paddingBottom: 0,
        paddingLeft: 0,
        paddingRight: 0,
        [outer.breakpoints.up('sm')]: { paddingLeft: 0, paddingRight: 0 },
      },
    },
    BackstageContentHeader: {
      container: { display: 'block', marginBottom: 0 },
      rightItemsBox: { display: 'none' },
    },
    BackstageSignInPage: {
      container: {
        '&&': {
          margin: 0,
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          gap: spacing[4],
        },
        '&& > li': { padding: 0 },
      },
      item: { maxWidth: 'none', width: '100%' },
    },
    BackstageInfoCard: {
      header: { padding: `${spacing[5]}px ${spacing[5]}px 0` },
      headerTitle: {
        fontSize: `${typography.size.lead / 16}rem`,
        fontWeight: typography.weight.bold,
        color: c.onSurface,
      },
    },
    MuiCard: {
      root: {
        borderRadius: shape.card,
        border: `1px solid ${c.outlineVariant}`,
        boxShadow: 'none',
        backgroundColor:
          mode === 'dark' ? c.surfaceContainer : c.surfaceContainerLowest,
      },
    },
    MuiCardContent: {
      root: {
        padding: `${spacing[2]}px ${spacing[5]}px`,
        color: c.onSurfaceVariant,
      },
    },
    MuiCardActions: {
      root: { padding: `${spacing[2]}px ${spacing[5]}px ${spacing[5]}px` },
    },
    MuiDivider: {
      root: { display: 'none' },
    },
    MuiButton: {
      outlinedPrimary: {
        minHeight: target.minimum,
        minWidth: 160,
        padding: `0 ${spacing[5]}px`,
        borderRadius: shape.control,
        border: 0,
        backgroundColor: c.primary,
        color: c.onPrimary,
        fontWeight: typography.weight.bold,
        fontSize: `${typography.size.body / 16}rem`,
        textTransform: 'none',
        boxShadow: `0 2px 0 ${
          brandTokens.palettes.primary[mode === 'dark' ? 40 : 10]
        }`,
        '&:hover': {
          border: 0,
          backgroundColor:
            mode === 'dark'
              ? brandTokens.palettes.primary[90]
              : brandTokens.palettes.primary[25],
        },
        '&:active': { transform: 'translateY(2px)', boxShadow: 'none' },
      },
    },
    MuiLinearProgress: {
      root: { borderRadius: shape.full },
    },
  };
}

function BrandPanel() {
  const classes = useStyles();
  const theme = useTheme<Theme>();
  const wide = useMediaQuery(theme.breakpoints.up('md'), { noSsr: true });
  const mode: BrandMode = theme.palette.type === 'dark' ? 'dark' : 'light';
  const { name } = brandTokens;
  return (
    <header className={classes.brand}>
      <LogoFull tone="reversed" height={56} style={{ maxWidth: '100%' }} />
      <div className={classes.identity}>
        <p className={classes.product}>{name.product}</p>
        <p className={classes.descriptor}>{name.productDescriptor}</p>
        <hr className={classes.rule} aria-hidden="true" />
        <p className={classes.summary}>
          Find services, APIs and documentation in one place, and create new
          components from approved templates.
        </p>
      </div>
      <div className={classes.demo} aria-hidden="true">
        {wide ? (
          <Suspense fallback={null}>
            <CatalogSearchDemo mode={mode} />
          </Suspense>
        ) : null}
      </div>
      <p className={classes.owner}>Built and run by {name.company}.</p>
    </header>
  );
}

function SignInHeading() {
  const classes = useStyles();
  return (
    <div>
      <h1 className={classes.heading}>Sign in to {brandTokens.name.product}</h1>
      <p className={classes.lead}>Choose an account to sign in with.</p>
    </div>
  );
}

/**
 * Full-bleed Solirius Reply sign-in screen. Renders the core Backstage
 * `SignInPage` inside a branded, GOV.UK-style accessible layout: one h1,
 * plain-English copy, 44px targets and visible focus. Authentication is
 * entirely handled by the core component.
 */
export function BrandedSignInPage(props: BrandedSignInPageProps) {
  const classes = useStyles();
  const nestedTheme = useCallback(
    (outer: Theme): Theme => ({
      ...outer,
      overrides: { ...outer.overrides, ...signInOverrides(outer) },
    }),
    [],
  );
  const single = 'provider' in props;

  return (
    <div className={classes.root}>
      <BrandPanel />
      <div className={classes.panel}>
        <div className={classes.column}>
          {single ? <SignInHeading /> : null}
          <ThemeProvider theme={nestedTheme}>
            {'provider' in props ? (
              <SignInPage {...props} />
            ) : (
              <SignInPage {...props} titleComponent={<SignInHeading />} />
            )}
          </ThemeProvider>
          <p className={classes.help}>
            If you cannot sign in, contact the {brandTokens.name.product}{' '}
            platform team. Read the <a href="/privacy.html">privacy notice</a>{' '}
            to see how sign-in details are used.
          </p>
        </div>
      </div>
    </div>
  );
}
