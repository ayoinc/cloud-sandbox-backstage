import {
  Link,
  sidebarConfig,
  useSidebarOpenState,
} from '@backstage/core-components';
import { makeStyles } from '@material-ui/core/styles';
import { LogoFull, LogoIcon } from './Logo';
import { brandTokens } from '../tokens/brandTokens';

const useStyles = makeStyles({
  root: {
    width: sidebarConfig.drawerWidthClosed,
    height: 3 * sidebarConfig.logoHeight,
    display: 'flex',
    flexFlow: 'row nowrap',
    alignItems: 'center',
    marginBottom: -14,
  },
  link: {
    display: 'inline-flex',
    alignItems: 'center',
    minHeight: 44,
    marginLeft: 24,
  },
});

/** Props for {@link BrandSidebarLogo}. */
export interface BrandSidebarLogoProps {
  /** Administrator-uploaded full logo URL (branding settings), if any. */
  logoFullSrc?: string | null;
  /** Administrator-uploaded icon URL (branding settings), if any. */
  logoIconSrc?: string | null;
  /** Route the logo links to. Defaults to the portal home. */
  to?: string;
}

/**
 * Sidebar logo: full lockup when the sidebar is open, running-figure icon when
 * it is collapsed. Must be rendered inside a Backstage `<Sidebar>`.
 */
export function BrandSidebarLogo(props: BrandSidebarLogoProps) {
  const { logoFullSrc, logoIconSrc, to = '/' } = props;
  const classes = useStyles();
  const { isOpen } = useSidebarOpenState();
  return (
    <div className={classes.root}>
      <Link
        to={to}
        underline="none"
        className={classes.link}
        aria-label={`${brandTokens.name.product} home`}
      >
        {isOpen ? (
          <LogoFull title="" src={logoFullSrc} height={36} />
        ) : (
          <LogoIcon title="" src={logoIconSrc} height={28} />
        )}
      </Link>
    </div>
  );
}
