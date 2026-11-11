/**
 * The portal's brand system. It carries no organisation's identity: the
 * name, logo, theme preset and primary colour are an administrator's choice,
 * held in {@link useBrandIdentity} and applied everywhere from there.
 *
 * GOV.UK Design System interaction and accessibility rules, Material Design 3
 * colour, shape and elevation.
 *
 * @packageDocumentation
 */

export {
  DEFAULT_PRESET,
  brandTokensFor,
  resolvePresetId,
} from './tokens/brandTokens';
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
export { presetIds } from './tokens/palette.generated';
export type {
  M3Role,
  M3Scheme,
  PresetId,
  TonalPaletteHex,
} from './tokens/palette.generated';
export { presets } from './tokens/presets';
export type { BrandPreset, ShapeScale } from './tokens/presets';

export {
  brandOverrides,
  getBrandIdentity,
  setBrandIdentity,
  useBrandIdentity,
  useLoadBrandIdentity,
} from './identity/brandIdentity';
export type { BrandIdentity } from './identity/brandIdentity';
export { contrastRatio } from './tokens/contrast';
export { contrastPairs } from './tokens/contrastPairs';
export type { ContrastPair } from './tokens/contrastPairs';
export { resolveBrandColors } from './tokens/overrides';
export type { BrandColorOverrides } from './tokens/overrides';

export {
  brandDarkTheme,
  brandLightTheme,
  brandThemes,
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
export type { LogoProps } from './logo/Logo';
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
