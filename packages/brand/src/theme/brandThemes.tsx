import { ThemeBlueprint } from '@backstage/plugin-app-react';
import DarkIcon from '@material-ui/icons/Brightness2';
import LightIcon from '@material-ui/icons/WbSunny';
import { BrandThemeProvider } from './BrandThemeProvider';

/** Solirius Reply light theme extension (`theme:app/solirius-light`). */
export const soliriusLightTheme = ThemeBlueprint.make({
  name: 'solirius-light',
  params: {
    theme: {
      id: 'solirius-light',
      title: 'Solirius Reply light',
      variant: 'light',
      icon: <LightIcon />,
      Provider: ({ children }) => (
        <BrandThemeProvider mode="light">{children}</BrandThemeProvider>
      ),
    },
  },
});

/** Solirius Reply dark theme extension (`theme:app/solirius-dark`). */
export const soliriusDarkTheme = ThemeBlueprint.make({
  name: 'solirius-dark',
  params: {
    theme: {
      id: 'solirius-dark',
      title: 'Solirius Reply dark',
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
export const brandThemes = [soliriusLightTheme, soliriusDarkTheme];
