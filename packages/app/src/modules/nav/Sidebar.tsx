import { Fragment } from 'react';
import {
  Sidebar,
  SidebarDivider,
  SidebarGroup,
  SidebarItem,
  SidebarScrollWrapper,
  SidebarSpace,
} from '@backstage/core-components';
import { identityApiRef, useApi } from '@backstage/frontend-plugin-api';
import {
  NavContentBlueprint,
  NavContentNavItem,
} from '@backstage/plugin-app-react';
import { NotificationsSidebarItem } from '@backstage/plugin-notifications';
import { MyGroupsSidebarItem } from '@backstage/plugin-org';
import { SidebarSearchModal } from '@backstage/plugin-search';
import { UserSettingsSignInAvatar } from '@backstage/plugin-user-settings';
import AccountTreeIcon from '@material-ui/icons/AccountTree';
import CategoryIcon from '@material-ui/icons/Category';
import DomainIcon from '@material-ui/icons/Domain';
import ExitToAppIcon from '@material-ui/icons/ExitToApp';
import ExtensionIcon from '@material-ui/icons/Extension';
import MenuIcon from '@material-ui/icons/Menu';
import GroupIcon from '@material-ui/icons/People';
import PersonIcon from '@material-ui/icons/Person';
import SearchIcon from '@material-ui/icons/Search';
import StorageIcon from '@material-ui/icons/Storage';
import WidgetsIcon from '@material-ui/icons/Widgets';
import { SidebarLogo } from './SidebarLogo';

const SidebarNavItem = (props: NavContentNavItem & { text?: string }) => (
  <SidebarItem
    icon={() => props.icon}
    to={props.href}
    text={props.text ?? props.title}
  />
);

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

const catalogKindItems = [
  { kind: 'component', text: 'Components', icon: WidgetsIcon },
  { kind: 'api', text: 'APIs', icon: ExtensionIcon },
  { kind: 'resource', text: 'Resources', icon: StorageIcon },
  { kind: 'template', text: 'Templates', icon: CategoryIcon },
  { kind: 'domain', text: 'Domains', icon: DomainIcon, divider: true },
  { kind: 'system', text: 'Systems', icon: AccountTreeIcon },
  { kind: 'group', text: 'Groups', icon: GroupIcon },
];

export const SidebarContent = NavContentBlueprint.make({
  params: {
    component: ({ navItems }) => {
      const nav = navItems.withComponent(SidebarNavItem);

      // Search and notifications have dedicated sidebar components below.
      nav.take('page:search');
      nav.take('page:notifications');

      // The catalog is linked through one shortcut per entity kind.
      const catalog = navItems.take('page:catalog');
      const docs = navItems.take('page:techdocs');
      const create = navItems.take('page:scaffolder');
      const apiExplorer = navItems.take('page:api-docs');
      const home = nav.take('page:home');
      const visualizer = nav.take('page:app-visualizer');
      const userSettings = nav.take('page:user-settings');

      return (
        <Sidebar>
          <SidebarLogo />
          <SidebarGroup label="Search" icon={<SearchIcon />} to="/search">
            <SidebarSearchModal />
          </SidebarGroup>
          <SidebarDivider />
          <SidebarGroup label="Menu" icon={<MenuIcon />}>
            {home}
            {catalog &&
              catalogKindItems.map(({ kind, text, icon, divider }) => (
                <Fragment key={kind}>
                  {divider && <SidebarDivider />}
                  <SidebarItem
                    icon={icon}
                    to={`${catalog.href}?filters[kind]=${kind}`}
                    text={text}
                  />
                </Fragment>
              ))}
            <SidebarDivider />
            {docs && <SidebarNavItem {...docs} text="Docs" />}
            {create && <SidebarNavItem {...create} text="Create..." />}
            {apiExplorer && (
              <SidebarNavItem {...apiExplorer} text="API explorer" />
            )}
            <SidebarScrollWrapper>
              {nav.rest({ sortBy: 'title' })}
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
            <MyGroupsSidebarItem
              singularTitle="Team"
              pluralTitle="Teams"
              icon={GroupIcon}
            />
            {catalog && (
              <SidebarItem
                icon={PersonIcon}
                to={`${catalog.href}?filters[kind]=user`}
                text="Users"
              />
            )}
            {visualizer}
            {userSettings}
            <SidebarDivider />
            <SignOutButton />
          </SidebarGroup>
        </Sidebar>
      );
    },
  },
});
