/**
 * Solirius Reply brand system for the Cloud Sandbox developer portal.
 *
 * GOV.UK Design System interaction and accessibility rules, Material Design 3
 * colour, shape and elevation, Solirius Reply identity.
 *
 * @packageDocumentation
 */

export { brandTokens } from './tokens/brandTokens';
export type {
  BrandMode,
  BrandModeColors,
  BrandTokens,
  HeaderColors,
  LinkColors,
  NavigationColors,
  StatusColors,
  StatusName,
} from './tokens/brandTokens';
export type {
  M3Role,
  M3Scheme,
  TonalPaletteHex,
} from './tokens/palette.generated';
export { contrastRatio } from './tokens/contrast';
export { contrastPairs } from './tokens/contrastPairs';
export type { ContrastPair } from './tokens/contrastPairs';
export { resolveBrandColors } from './tokens/overrides';
export type { BrandColorOverrides } from './tokens/overrides';

export {
  brandThemes,
  soliriusDarkTheme,
  soliriusLightTheme,
} from './theme/brandThemes';
export { BrandThemeProvider } from './theme/BrandThemeProvider';
export type { BrandThemeProviderProps } from './theme/BrandThemeProvider';
export { createBrandTheme } from './theme/muiTheme';
export { buiThemeCss, buiVariables, toastVariables } from './theme/buiCss';

export {
  BrandedSignInPage,
  brandSignInProviders,
} from './signin/BrandedSignInPage';
export type { BrandedSignInPageProps } from './signin/BrandedSignInPage';

export { LogoFull, LogoIcon } from './logo/Logo';
export type { LogoProps, LogoTone } from './logo/Logo';
export { BrandSidebarLogo } from './logo/BrandSidebarLogo';
export type { BrandSidebarLogoProps } from './logo/BrandSidebarLogo';

export { techdocsBrandCss } from './techdocs/techdocsBrandCss';
export {
  TechDocsBrandStyles,
  techDocsBrandAddon,
} from './techdocs/TechDocsBrandStyles';

export { brandTranslations } from './translations';

export { RunActivityCard } from './activity/RunActivityCard';
export type {
  RunActivityCardProps,
  RunActivityLine,
} from './activity/RunActivityCard';
