import {
  createUnifiedTheme,
  defaultComponentThemes,
  type PageTheme,
  type UnifiedTheme,
  type UnifiedThemeOptions,
} from '@backstage/theme';
import { brandTokensFor } from '../tokens/brandTokens';
import type {
  BrandMode,
  BrandModeColors,
  BrandTokens,
} from '../tokens/brandTokens';
import { resolveBrandColors } from '../tokens/overrides';
import type { BrandColorOverrides } from '../tokens/overrides';

/** Page theme ids Backstage and its plugins request via `<Page themeId>`. */
const PAGE_THEME_IDS = [
  'home',
  'documentation',
  'tool',
  'service',
  'website',
  'library',
  'other',
  'app',
  'apis',
  'card',
] as const;

/**
 * Solid branded page headers. No decorative burst shapes: identity comes from
 * the dark secondary surface and a primary accent rule, not ornament.
 */
function pageThemes(c: BrandModeColors): Record<string, PageTheme> {
  const header: PageTheme = {
    colors: [c.header.background, c.header.background],
    shape: 'none',
    backgroundImage: `linear-gradient(90deg, ${c.header.background}, ${c.header.background})`,
    fontColor: c.header.text,
  };
  return Object.fromEntries(PAGE_THEME_IDS.map(id => [id, header]));
}

function palette(
  mode: BrandMode,
  c: BrandModeColors,
  tokens: BrandTokens,
): UnifiedThemeOptions['palette'] {
  const { status } = c;
  const isDark = mode === 'dark';
  const p = tokens.palettes;
  return {
    type: mode,
    mode,
    primary: { main: c.primary, contrastText: c.onPrimary },
    secondary: { main: c.secondary, contrastText: c.onSecondary },
    error: { main: c.error, contrastText: c.onError },
    warning: {
      main: status.warning.text,
      contrastText: isDark ? p.warning[10] : p.warning[100],
    },
    info: {
      main: status.info.text,
      contrastText: isDark ? c.onPrimary : '#ffffff',
    },
    success: {
      main: status.success.text,
      contrastText: isDark ? p.success[10] : p.success[100],
    },
    background: {
      default: isDark ? c.surface : c.surfaceContainerLow,
      paper: isDark ? c.surfaceContainerLow : c.surfaceContainerLowest,
    },
    text: {
      primary: c.onSurface,
      secondary: c.onSurfaceVariant,
      disabled: isDark ? p.neutral[50] : p.neutral[60],
    },
    divider: c.outlineVariant,
    status: {
      ok: status.success.text,
      warning: status.warning.text,
      error: status.danger.text,
      running: status.info.text,
      pending: c.onSurfaceVariant,
      aborted: c.outline,
    },
    bursts: {
      fontColor: c.header.text,
      slackChannelText: c.header.text,
      backgroundColor: { default: c.header.background },
      gradient: {
        linear: `linear-gradient(90deg, ${c.header.background}, ${c.header.background})`,
      },
    },
    banner: {
      info: status.info.solid,
      error: status.danger.solid,
      warning: p.warning[40],
      text: '#ffffff',
      link: '#ffffff',
      closeButtonColor: '#ffffff',
    },
    border: c.outlineVariant,
    textContrast: c.onSurface,
    textVerySubtle: c.outlineVariant,
    textSubtle: c.onSurfaceVariant,
    highlight: c.secondaryContainer,
    errorBackground: status.danger.container,
    warningBackground: status.warning.container,
    infoBackground: status.info.container,
    errorText: status.danger.onContainer,
    infoText: status.info.onContainer,
    warningText: status.warning.onContainer,
    link: c.link.default,
    linkHover: c.link.hover,
    gold: p.warning[80],
    navigation: {
      background: c.navigation.background,
      indicator: c.navigation.indicator,
      color: c.navigation.text,
      selectedColor: c.navigation.selectedText,
      navItem: { hoverBackground: c.navigation.hoverBackground },
      submenu: { background: c.navigation.submenuBackground },
    },
    pinSidebarButton: {
      icon: c.navigation.background,
      background: c.navigation.text,
    },
    tabbar: { indicator: c.primary },
    code: { background: c.surfaceContainer },
  };
}

function components(
  c: BrandModeColors,
  tokens: BrandTokens,
): UnifiedThemeOptions['components'] {
  const { shape, target, focus, typography, elevation } = tokens;
  const baseline = defaultComponentThemes?.MuiCssBaseline?.styleOverrides;
  const outlined = `1px solid ${c.outlineVariant}`;

  return {
    MuiCssBaseline: {
      styleOverrides: theme => {
        const defaults =
          typeof baseline === 'function' ? baseline(theme) : baseline;
        const base =
          defaults && typeof defaults === 'object' && !Array.isArray(defaults)
            ? defaults
            : {};
        const body =
          'body' in base && base.body && typeof base.body === 'object'
            ? base.body
            : {};
        return {
          ...base,
          body: {
            ...body,
            fontSize: `${typography.size.body / 16}rem`,
            lineHeight: typography.lineHeight.body,
          },
          'h1, h2, h3, h4, h5, h6': {
            fontFamily: typography.fontFamily,
          },
        };
      },
    },
    MuiButton: {
      defaultProps: { disableElevation: true },
      styleOverrides: {
        root: {
          borderRadius: shape.control,
          textTransform: 'none',
          fontWeight: typography.weight.bold,
          letterSpacing: 'normal',
          minHeight: target.minimum,
          paddingLeft: 16,
          paddingRight: 16,
        },
        sizeSmall: { minHeight: 32 },
        sizeLarge: { minHeight: 48 },
        outlined: { borderColor: c.outline },
        outlinedPrimary: { borderColor: c.primary },
      },
    },
    MuiIconButton: {
      styleOverrides: {
        root: { minWidth: target.minimum, minHeight: target.minimum },
        sizeSmall: { minWidth: 32, minHeight: 32 },
      },
    },
    MuiPaper: {
      styleOverrides: {
        rounded: { borderRadius: shape.card },
        elevation1: { boxShadow: 'none', border: outlined },
        elevation2: { boxShadow: 'none', border: outlined },
        elevation4: { boxShadow: elevation.level1, border: outlined },
        elevation8: { boxShadow: elevation.level2, border: outlined },
        elevation24: { boxShadow: elevation.level3 },
      },
    },
    MuiDialog: {
      styleOverrides: {
        paper: { borderRadius: shape.dialog },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: { borderRadius: shape.full, fontWeight: typography.weight.bold },
      },
    },
    MuiOutlinedInput: {
      styleOverrides: {
        root: {
          borderRadius: shape.control,
          '&.Mui-focused': {
            boxShadow: `0 0 0 ${focus.width}px ${focus.color}`,
          },
          '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
            borderColor: c.onSurface,
            borderWidth: 2,
          },
        },
        notchedOutline: { borderColor: c.outline },
      },
    },
    MuiLink: {
      defaultProps: { underline: 'always' },
      styleOverrides: {
        root: {
          textDecorationThickness: 'max(1px, 0.0625rem)',
          textUnderlineOffset: '0.15em',
          '&:hover': { textDecorationThickness: 'max(3px, 0.1875rem)' },
        },
      },
    },
    MuiTooltip: {
      styleOverrides: {
        tooltip: {
          backgroundColor: c.inverseSurface,
          color: c.inverseOnSurface,
          fontSize: `${typography.size.sm / 16}rem`,
          borderRadius: shape.control,
        },
      },
    },
    MuiAlert: {
      styleOverrides: {
        root: { borderRadius: shape.card },
      },
    },
    BackstageHeader: {
      styleOverrides: {
        header: {
          boxShadow: 'none',
          borderBottom: `4px solid ${c.header.accent}`,
        },
        title: { fontWeight: typography.weight.bold },
      },
    },
    BackstageInfoCard: {
      styleOverrides: {
        headerTitle: { fontWeight: typography.weight.bold },
      },
    },
  };
}

/**
 * Creates the MUI v4 + v5 unified theme for `mode`. `overrides` carries the
 * organisation's preset and primary colour; without it the default preset
 * is used.
 */
export function createBrandTheme(
  mode: BrandMode,
  overrides?: BrandColorOverrides,
): UnifiedTheme {
  const c = resolveBrandColors(mode, overrides);
  const tokens = brandTokensFor(overrides?.preset);
  const { typography } = tokens;
  const heading = (size: number, marginBottom: number) => ({
    fontFamily: typography.fontFamily,
    fontSize: size,
    fontWeight: typography.weight.bold,
    marginBottom,
  });
  return createUnifiedTheme({
    palette: palette(mode, c, tokens),
    fontFamily: typography.fontFamily,
    htmlFontSize: typography.htmlFontSize,
    typography: {
      htmlFontSize: typography.htmlFontSize,
      fontFamily: typography.fontFamily,
      h1: heading(typography.size.h1, 12),
      h2: heading(typography.size.h2, 10),
      h3: heading(typography.size.h3, 8),
      h4: heading(typography.size.h4, 6),
      h5: heading(typography.size.h5, 4),
      h6: heading(typography.size.h6, 2),
    },
    defaultPageTheme: 'home',
    pageTheme: pageThemes(c),
    components: components(c, tokens),
  });
}
