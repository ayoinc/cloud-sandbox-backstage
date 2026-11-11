import { Suspense, lazy } from 'react';
import { makeStyles, useTheme } from '@material-ui/core/styles';
import type { Theme } from '@material-ui/core/styles';
import useMediaQuery from '@material-ui/core/useMediaQuery';
import { useBrandIdentity } from '../identity/brandIdentity';
import { LogoFull } from '../logo/Logo';
import type { BrandMode } from '../tokens/brandTokens';
import { activeBrand } from './activeBrand';
import { SignInChoices } from './SignInChoices';
import type { SignInChoicesProps } from './SignInChoices';

// Dynamic import: the demo is decorative, so the sign-in page's first paint must not wait for its code.
const CatalogSearchDemo = lazy(() => import('../stageshow/CatalogSearchDemo'));

/** Props for {@link BrandedSignInPage}. */
export type BrandedSignInPageProps = SignInChoicesProps;

const useStyles = makeStyles((theme: Theme) => {
  const { mode, tokens, c } = activeBrand(theme);
  const { typography, spacing } = tokens;
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
      color: c.navigation.selectedText,
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
    panel: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: spacing[8],
      padding: `${spacing[10]}px ${spacing[4]}px ${spacing[6]}px`,
      [theme.breakpoints.up('md')]: {
        minHeight: '100vh',
        padding: `${spacing[15]}px ${spacing[12]}px ${spacing[8]}px`,
      },
    },
    column: {
      width: '100%',
      maxWidth: 520,
      // Takes the space above the footer, with the form in the middle of it.
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
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
      margin: `${spacing[6]}px 0 0`,
      fontSize: `${typography.size.body / 16}rem`,
      lineHeight: typography.lineHeight.body,
      color: c.onSurfaceVariant,
    },
    footer: {
      width: '100%',
      maxWidth: 520,
      paddingTop: spacing[4],
      borderTop: `1px solid ${c.outlineVariant}`,
      fontSize: `${typography.size.sm / 16}rem`,
      '& ul': {
        listStyle: 'none',
        margin: 0,
        padding: 0,
        display: 'flex',
        flexWrap: 'wrap',
        gap: `${spacing[2]}px ${spacing[6]}px`,
      },
      '& a': {
        // Links look like links: underlined, in the link colour.
        color: c.link.default,
        textDecoration: 'underline',
        textUnderlineOffset: '0.15em',
        '&:hover': { color: c.link.hover },
        '&:focus-visible': {
          outline: `${tokens.focus.width}px solid ${tokens.focus.color}`,
          backgroundColor: tokens.focus.color,
          color: tokens.focus.text,
          textDecoration: 'none',
        },
      },
    },
  };
});

function BrandPanel() {
  const classes = useStyles();
  const theme = useTheme<Theme>();
  const wide = useMediaQuery(theme.breakpoints.up('md'), { noSsr: true });
  const mode: BrandMode = theme.palette.type === 'dark' ? 'dark' : 'light';
  const { name, logoFullUrl } = useBrandIdentity();
  return (
    <header className={classes.brand}>
      {/* Nothing stands in for a logo or a name that has not been set. */}
      {logoFullUrl ? (
        <LogoFull
          height={56}
          style={{ maxWidth: '100%', alignSelf: 'flex-start' }}
        />
      ) : null}
      <div className={classes.identity}>
        {name ? <p className={classes.product}>{name}</p> : null}
        <p className={classes.descriptor}>Developer portal</p>
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
    </header>
  );
}

function SignInHeading() {
  const classes = useStyles();
  const { name } = useBrandIdentity();
  return (
    <div>
      <h1 className={classes.heading}>
        {name ? `Sign in to ${name}` : 'Sign in'}
      </h1>
      <p className={classes.lead}>Choose how to sign in.</p>
    </div>
  );
}

/** The public pages every visitor can read, signed in or not. */
const PUBLIC_PAGES = [
  ['/privacy.html', 'Privacy notice'],
  ['/cookies.html', 'Cookies'],
  ['/guides.html', 'Guides'],
  ['/sitemap.html', 'Sitemap'],
];

/**
 * Full-bleed sign-in screen. At an organisation's address (`/o/<slug>`) it
 * takes the name, logo and theme the organisation's owner set; anywhere
 * else it is the neutral portal. One button for each way of signing in, in
 * a GOV.UK-style accessible layout: one h1, plain-English copy, 44px targets
 * and visible focus, and a footer with the pages anyone can read.
 */
export function BrandedSignInPage(props: BrandedSignInPageProps) {
  const classes = useStyles();
  return (
    <div className={classes.root}>
      <BrandPanel />
      <div className={classes.panel}>
        <main className={classes.column}>
          <SignInHeading />
          <SignInChoices {...props} />
          <p className={classes.help}>
            If you cannot sign in, ask the person who sent you this portal's
            address.
          </p>
        </main>
        <footer className={classes.footer}>
          <nav aria-label="Portal information">
            <ul>
              {PUBLIC_PAGES.map(([href, label]) => (
                <li key={href}>
                  <a href={href}>{label}</a>
                </li>
              ))}
            </ul>
          </nav>
        </footer>
      </div>
    </div>
  );
}
