import {
  Link,
  sidebarConfig,
  useSidebarOpenState,
} from '@backstage/core-components';
import { makeStyles } from '@material-ui/core/styles';
import { LogoFull, LogoIcon } from './Logo';

const useStyles = makeStyles(theme => ({
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
    // The name beside the plain mark takes the sidebar's own text colour.
    color: theme.palette.navigation.selectedColor,
    maxWidth: sidebarConfig.drawerWidthOpen - 48,
  },
}));

/** Props for {@link BrandSidebarLogo}. */
export interface BrandSidebarLogoProps {
  /** Route the logo links to. Defaults to the portal home. */
  to?: string;
}

/**
 * Sidebar logo: the organisation's full logo when the sidebar is open, its
 * icon when collapsed. Must be rendered inside a Backstage `<Sidebar>`.
 */
export function BrandSidebarLogo(props: BrandSidebarLogoProps) {
  const { to = '/' } = props;
  const classes = useStyles();
  const { isOpen } = useSidebarOpenState();
  return (
    <div className={classes.root}>
      <Link to={to} underline="none" className={classes.link} aria-label="Home">
        {isOpen ? (
          <LogoFull title="" height={36} />
        ) : (
          <LogoIcon title="" height={28} />
        )}
      </Link>
    </div>
  );
}
