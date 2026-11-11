import { ThemeBlueprint } from '@backstage/plugin-app-react';
import DarkIcon from '@material-ui/icons/Brightness2';
import LightIcon from '@material-ui/icons/WbSunny';
import { BrandThemeProvider } from './BrandThemeProvider';

/** Light theme extension (`theme:app/brand-light`). */
export const brandLightTheme = ThemeBlueprint.make({
  name: 'brand-light',
  params: {
    theme: {
      id: 'brand-light',
      title: 'Light',
      variant: 'light',
      icon: <LightIcon />,
      Provider: ({ children }) => (
        <BrandThemeProvider mode="light">{children}</BrandThemeProvider>
      ),
    },
  },
});

/** Dark theme extension (`theme:app/brand-dark`). */
export const brandDarkTheme = ThemeBlueprint.make({
  name: 'brand-dark',
  params: {
    theme: {
      id: 'brand-dark',
      title: 'Dark',
      variant: 'dark',
      icon: <DarkIcon />,
      Provider: ({ children }) => (
        <BrandThemeProvider mode="dark">{children}</BrandThemeProvider>
      ),
    },
  },
});

/**
 * Brand theme extensions. Install them in an `app` frontend module; they are
 * restricted to the app plugin by `ThemeBlueprint`.
 */
export const brandThemes = [brandLightTheme, brandDarkTheme];
