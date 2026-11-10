import '../fonts';
import './bui-deprecated-aliases.css';
import { useMemo } from 'react';
import type { ReactNode } from 'react';
import { UnifiedThemeProvider } from '@backstage/theme';
import type { BrandMode } from '../tokens/brandTokens';
import type { BrandColorOverrides } from '../tokens/overrides';
import { buiThemeCss } from './buiCss';
import { createBrandTheme } from './muiTheme';

/** Props for {@link BrandThemeProvider}. */
export interface BrandThemeProviderProps {
  mode: BrandMode;
  /** Administrator branding overrides applied on top of the brand defaults. */
  overrides?: BrandColorOverrides;
  children: ReactNode;
}

/**
 * Applies the Solirius Reply theme to MUI v4, MUI v5 and Backstage UI
 * (`--bui-*` variables, toasts and focus styles) for the given mode.
 * Nest a second provider with `overrides` to apply admin branding at runtime.
 */
export function BrandThemeProvider(props: BrandThemeProviderProps) {
  const { mode, overrides, children } = props;
  const primaryColor = overrides?.primaryColor ?? null;
  const theme = useMemo(
    () => createBrandTheme(mode, { primaryColor }),
    [mode, primaryColor],
  );
  const css = useMemo(
    () => buiThemeCss(mode, { primaryColor }),
    [mode, primaryColor],
  );
  return (
    <UnifiedThemeProvider theme={theme} themeName={`solirius-${mode}`}>
      <style data-brand-theme={`solirius-${mode}`}>{css}</style>
      {children}
    </UnifiedThemeProvider>
  );
}
