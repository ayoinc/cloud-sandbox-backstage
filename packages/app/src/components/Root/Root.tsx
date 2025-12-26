import { PropsWithChildren } from 'react';
import { makeStyles } from '@material-ui/core';
import ExtensionIcon from '@material-ui/icons/Extension';
import LibraryBooks from '@material-ui/icons/LibraryBooks';
import CreateComponentIcon from '@material-ui/icons/AddCircleOutline';
import ExitToAppIcon from '@material-ui/icons/ExitToApp';
import LogoFull from './LogoFull';
import LogoIcon from './LogoIcon';
import {
  Settings as SidebarSettings,
  UserSettingsSignInAvatar,
} from '@backstage/plugin-user-settings';
import { identityApiRef, useApi } from '@backstage/core-plugin-api';
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
// Additional icons for catalog kinds
import CategoryIcon from '@material-ui/icons/Category';
import WidgetsIcon from '@material-ui/icons/Widgets';
import StorageIcon from '@material-ui/icons/Storage';
import AccountTreeIcon from '@material-ui/icons/AccountTree';
import DomainIcon from '@material-ui/icons/Domain';
import PersonIcon from '@material-ui/icons/Person';

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
    <SidebarItem icon={ExitToAppIcon} text="Sign Out" onClick={handleSignOut} />
  );
};

export const Root = ({ children }: PropsWithChildren<{}>) => (
  <SidebarPage>
    <Sidebar>
      <SidebarLogo />
      <SidebarGroup label="Search" icon={<SearchIcon />} to="/search">
        <SidebarSearchModal />
      </SidebarGroup>
      <SidebarDivider />
      <SidebarGroup label="Menu" icon={<MenuIcon />}>
        {/* Catalog entity kinds */}
        <SidebarItem
          icon={WidgetsIcon}
          to="catalog?filters[kind]=component"
          text="Components"
        />
        <SidebarItem
          icon={ExtensionIcon}
          to="catalog?filters[kind]=api"
          text="APIs"
        />
        <SidebarItem
          icon={StorageIcon}
          to="catalog?filters[kind]=resource"
          text="Resources"
        />
        <SidebarItem
          icon={CategoryIcon}
          to="catalog?filters[kind]=template"
          text="Templates"
        />
        <SidebarDivider />
        <SidebarItem
          icon={DomainIcon}
          to="catalog?filters[kind]=domain"
          text="Domains"
        />
        <SidebarItem
          icon={AccountTreeIcon}
          to="catalog?filters[kind]=system"
          text="Systems"
        />
        <SidebarItem
          icon={GroupIcon}
          to="catalog?filters[kind]=group"
          text="Groups"
        />
        <SidebarDivider />
        <SidebarItem icon={LibraryBooks} to="docs" text="Docs" />
        <SidebarItem icon={CreateComponentIcon} to="create" text="Create..." />
        <SidebarScrollWrapper>
          {/* Items in this group will be scrollable if they run out of space */}
        </SidebarScrollWrapper>
      </SidebarGroup>
      <SidebarSpace />
      <SidebarDivider />
      <SidebarGroup
        label="Settings"
        icon={<UserSettingsSignInAvatar />}
        to="/settings"
      >
        <MyGroupsSidebarItem
          singularTitle="Team"
          pluralTitle="Teams"
          icon={GroupIcon}
        />
        <SidebarItem
          icon={PersonIcon}
          to="catalog?filters[kind]=user"
          text="Users"
        />
        <SidebarSettings />
        <SidebarDivider />
        <SignOutButton />
      </SidebarGroup>
    </Sidebar>
    {children}
  </SidebarPage>
);
