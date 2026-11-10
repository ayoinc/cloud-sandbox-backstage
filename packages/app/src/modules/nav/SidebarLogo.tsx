import { BrandSidebarLogo } from '@internal/brand';
import { useBranding } from '../../components/branding';

/** Sidebar logo: admin-uploaded artwork when set, otherwise the Solirius Reply logo. */
export const SidebarLogo = () => {
  const { settings } = useBranding();
  return (
    <BrandSidebarLogo
      logoFullSrc={settings.logoFullUrl}
      logoIconSrc={settings.logoIconUrl}
    />
  );
};
