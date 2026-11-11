import '../fonts';
import './bui-deprecated-aliases.css';
import { useMemo } from 'react';
import type { ReactNode } from 'react';
import { UnifiedThemeProvider } from '@backstage/theme';
import { useBrandIdentity } from '../identity/brandIdentity';
import type { BrandMode } from '../tokens/brandTokens';
import { resolvePresetId } from '../tokens/brandTokens';
import { buiThemeCss } from './buiCss';
import { createBrandTheme } from './muiTheme';

/** Props for {@link BrandThemeProvider}. */
export interface BrandThemeProviderProps {
  mode: BrandMode;
  children: ReactNode;
}

/**
 * Applies the portal's theme to MUI v4, MUI v5 and Backstage UI (`--bui-*`
 * variables, toasts and focus styles) for the given mode. The preset and
 * primary colour are those the owner of the organisation being shown set,
 * and change as soon as they do.
 */
export function BrandThemeProvider(props: BrandThemeProviderProps) {
  const { mode, children } = props;
  const { themePreset, primaryColor } = useBrandIdentity();
  const preset = resolvePresetId(themePreset);
  const theme = useMemo(
    () => createBrandTheme(mode, { preset, primaryColor }),
    [mode, preset, primaryColor],
  );
  const css = useMemo(
    () => buiThemeCss(mode, { preset, primaryColor }),
    [mode, preset, primaryColor],
  );
  const name = `${preset}-${mode}`;
  return (
    <UnifiedThemeProvider theme={theme} themeName={name}>
      <style data-brand-theme={name}>{css}</style>
      {children}
    </UnifiedThemeProvider>
  );
}
