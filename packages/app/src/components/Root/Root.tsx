import { PropsWithChildren } from 'react';
import { makeStyles } from '@material-ui/core';
import HomeIcon from '@material-ui/icons/Home';
import ExtensionIcon from '@material-ui/icons/Extension';
import LibraryBooks from '@material-ui/icons/LibraryBooks';
import CreateComponentIcon from '@material-ui/icons/AddCircleOutline';
import CategoryIcon from '@material-ui/icons/Category';
import LogoFull from './LogoFull';
import LogoIcon from './LogoIcon';
import {
  Settings as SidebarSettings,
  UserSettingsSignInAvatar,
} from '@backstage/plugin-user-settings';
import { identityApiRef, useApi } from '@backstage/core-plugin-api';
import ExitToAppIcon from '@material-ui/icons/ExitToApp';
import { SidebarSearchModal } from '@backstage/plugin-search';
import {
  Sidebar,
  sidebarConfig,
  SidebarDivider,
  SidebarGroup,
  SidebarItem,
  SidebarPage,
  SidebarScrollWrapper,
  SidebarSpace,
  useSidebarOpenState,
  Link,
} from '@backstage/core-components';
import MenuIcon from '@material-ui/icons/Menu';
import SearchIcon from '@material-ui/icons/Search';
import { MyGroupsSidebarItem } from '@backstage/plugin-org';
import GroupIcon from '@material-ui/icons/People';
import PersonIcon from '@material-ui/icons/Person';
import GitHubIcon from '@material-ui/icons/GitHub';
import { NotificationsSidebarItem } from '@backstage/plugin-notifications';
import { useIsGuest } from '../../hooks/useIsGuest';

// =============================================================================
// PLACEHOLDER: Enterprise Plugin Icons (uncomment when configured)
// =============================================================================
// import MoneyIcon from '@material-ui/icons/MonetizationOn';  // Cost Insights

const useSidebarLogoStyles = makeStyles({
  root: {
    width: sidebarConfig.drawerWidthClosed,
    height: 3 * sidebarConfig.logoHeight,
    display: 'flex',
    flexFlow: 'row nowrap',
    alignItems: 'center',
    marginBottom: -14,
  },
  link: {
    width: sidebarConfig.drawerWidthClosed,
    marginLeft: 24,
  },
});

const SidebarLogo = () => {
  const classes = useSidebarLogoStyles();
  const { isOpen } = useSidebarOpenState();

  return (
    <div className={classes.root}>
      <Link to="/" underline="none" className={classes.link} aria-label="Home">
        {isOpen ? <LogoFull /> : <LogoIcon />}
      </Link>
    </div>
  );
};

const SignOutButton = () => {
  const identityApi = useApi(identityApiRef);

  const handleSignOut = async () => {
    await identityApi.signOut();
    window.location.reload();
  };

  return (
    <SidebarItem
      icon={ExitToAppIcon}
      text="Sign Out"
      onClick={handleSignOut}
    />
  );
};

export const Root = ({ children }: PropsWithChildren<{}>) => {
  const isGuest = useIsGuest();

  return (
    <SidebarPage>
      <Sidebar>
        <SidebarLogo />
        <SidebarGroup label="Search" icon={<SearchIcon />} to="/search">
          <SidebarSearchModal />
        </SidebarGroup>
        <SidebarDivider />
        <SidebarGroup label="Menu" icon={<MenuIcon />}>
          <SidebarItem icon={HomeIcon} to="catalog" text="Home" />
          <SidebarItem icon={CategoryIcon} to="catalog?filters[kind]=component" text="Components" />
          <SidebarItem icon={ExtensionIcon} to="api-docs" text="APIs" />
          <SidebarItem icon={LibraryBooks} to="docs" text="Docs" />
          {!isGuest && (
            <SidebarItem icon={CreateComponentIcon} to="create" text="Create..." />
          )}
          {!isGuest && (
            <>
              <SidebarDivider />
              <MyGroupsSidebarItem
                singularTitle="My Group"
                pluralTitle="My Groups"
                icon={GroupIcon}
              />
              <SidebarItem icon={GroupIcon} to="catalog?filters[kind]=group" text="Teams" />
              <SidebarItem icon={PersonIcon} to="catalog?filters[kind]=user" text="Users" />
              <SidebarItem icon={GitHubIcon} to="github-org" text="GitHub Org" />
            </>
          )}
          <SidebarDivider />
          <SidebarScrollWrapper>
            {/* ============================================================= */}
            {/* PLACEHOLDER: Enterprise Plugin Sidebar Items                  */}
            {/* ============================================================= */}
            {/* Uncomment when Cost Insights is configured                    */}
            {/* <SidebarItem icon={MoneyIcon} to="cost-insights" text="Cost Insights" /> */}
          </SidebarScrollWrapper>
        </SidebarGroup>
        <SidebarSpace />
        <SidebarDivider />
        <NotificationsSidebarItem />
        <SidebarDivider />
        <SidebarGroup
          label="Settings"
          icon={<UserSettingsSignInAvatar />}
          to="/settings"
        >
          <SidebarSettings />
          <SidebarDivider />
          <SignOutButton />
        </SidebarGroup>
      </Sidebar>
      {children}
    </SidebarPage>
  );
};
