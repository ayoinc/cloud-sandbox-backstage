import { m3Schemes, m3Source, m3TonalPalettes } from './palette.generated';
import type { M3Scheme } from './palette.generated';

/** Light or dark colour mode. */
export type BrandMode = 'light' | 'dark';

/**
 * Colours for one status (success, warning, danger, info).
 *
 * - `text`: status text or icon on the page surface.
 * - `container` / `onContainer`: tinted panel and the text placed on it.
 * - `border`: 3:1 non-text indicator against the page surface.
 * - `solid` / `onSolid`: high-visibility filled variant (toasts, banners).
 */
export interface StatusColors {
  text: string;
  container: string;
  onContainer: string;
  border: string;
  solid: string;
  onSolid: string;
}

/** Status keys. Status is never conveyed by colour alone. */
export type StatusName = 'success' | 'warning' | 'danger' | 'info';

/** Navigation (sidebar) colours. */
export interface NavigationColors {
  background: string;
  text: string;
  selectedText: string;
  indicator: string;
  hoverBackground: string;
  submenuBackground: string;
}

/** Link colours. */
export interface LinkColors {
  default: string;
  hover: string;
  visited: string;
}

/** Page header colours used by Backstage page themes. */
export interface HeaderColors {
  background: string;
  text: string;
  accent: string;
}

/** Full colour set for one mode: every M3 role plus portal-specific roles. */
export interface BrandModeColors extends M3Scheme {
  status: Record<StatusName, StatusColors>;
  navigation: NavigationColors;
  link: LinkColors;
  header: HeaderColors;
}

const tone = m3TonalPalettes;

/** Exact identity colours sampled from the Solirius Reply logo artwork. */
const identity = {
  /** Running figure and "SOLIRIUS" wordmark. */
  soliriusBlue: m3Source.soliriusBlue,
  /** "REPLY" wordmark. */
  replyTeal: m3Source.replyTeal,
  /** solirius.com secondary indigo. */
  soliriusIndigo: m3Source.soliriusIndigo,
  /** solirius.com pale blue tint, rgb(205, 224, 246). */
  soliriusMist: '#cde0f6',
  white: '#ffffff',
} as const;

const light: BrandModeColors = {
  ...m3Schemes.light,
  status: {
    success: {
      text: tone.success[40],
      container: tone.success[95],
      onContainer: tone.success[10],
      border: tone.success[40],
      solid: tone.success[40],
      onSolid: tone.success[100],
    },
    warning: {
      text: tone.warning[40],
      container: tone.warning[95],
      onContainer: tone.warning[10],
      border: tone.warning[50],
      solid: tone.warning[70],
      onSolid: tone.warning[10],
    },
    danger: {
      text: m3Schemes.light.error,
      container: m3Schemes.light.errorContainer,
      onContainer: m3Schemes.light.onErrorContainer,
      border: m3Schemes.light.error,
      solid: tone.error[40],
      onSolid: tone.error[100],
    },
    info: {
      text: m3Schemes.light.primary,
      container: m3Schemes.light.primaryContainer,
      onContainer: m3Schemes.light.onPrimaryContainer,
      border: m3Schemes.light.primary,
      solid: identity.soliriusBlue,
      onSolid: identity.white,
    },
  },
  navigation: {
    background: identity.replyTeal,
    text: tone.secondary[90],
    selectedText: identity.white,
    indicator: tone.primary[80],
    hoverBackground: tone.secondary[30],
    submenuBackground: tone.secondary[20],
  },
  link: {
    default: m3Schemes.light.primary,
    hover: tone.primary[20],
    visited: m3Schemes.light.tertiary,
  },
  header: {
    background: identity.replyTeal,
    text: identity.white,
    accent: tone.primary[70],
  },
};

const dark: BrandModeColors = {
  ...m3Schemes.dark,
  status: {
    success: {
      text: tone.success[80],
      container: tone.success[30],
      onContainer: tone.success[90],
      border: tone.success[70],
      solid: tone.success[40],
      onSolid: tone.success[100],
    },
    warning: {
      text: tone.warning[80],
      container: tone.warning[30],
      onContainer: tone.warning[90],
      border: tone.warning[70],
      solid: tone.warning[70],
      onSolid: tone.warning[10],
    },
    danger: {
      text: m3Schemes.dark.error,
      container: m3Schemes.dark.errorContainer,
      onContainer: m3Schemes.dark.onErrorContainer,
      border: tone.error[70],
      solid: tone.error[40],
      onSolid: tone.error[100],
    },
    info: {
      text: m3Schemes.dark.primary,
      container: m3Schemes.dark.primaryContainer,
      onContainer: m3Schemes.dark.onPrimaryContainer,
      border: tone.primary[70],
      solid: identity.soliriusBlue,
      onSolid: identity.white,
    },
  },
  navigation: {
    background: tone.secondary[10],
    text: tone.secondary[90],
    selectedText: identity.white,
    indicator: tone.primary[80],
    hoverBackground: tone.secondary[20],
    submenuBackground: tone.secondary[17],
  },
  link: {
    default: m3Schemes.dark.primary,
    hover: tone.primary[90],
    visited: m3Schemes.dark.tertiary,
  },
  header: {
    background: tone.secondary[20],
    text: identity.white,
    accent: tone.primary[80],
  },
};

/**
 * Solirius Reply brand tokens: the single source of truth for colour, shape,
 * spacing, typography and focus across MUI v4/v5, Backstage UI and TechDocs.
 *
 * Colour roles are Material Design 3 roles generated from the logo blue seed
 * (see scripts/generate-palette.mjs). Interaction and accessibility rules
 * follow the GOV.UK Design System (WCAG 2.2 AA, yellow focus, 44px targets).
 */
export const brandTokens = {
  name: {
    company: 'Solirius Reply',
    product: 'Cloud Sandbox',
    productDescriptor: 'Developer portal',
  },
  identity,
  palettes: m3TonalPalettes,
  color: { light, dark } as Record<BrandMode, BrandModeColors>,
  /**
   * GOV.UK-style focus: yellow with a dark edge so the indicator passes 3:1
   * against any light or dark surface.
   */
  focus: {
    color: '#ffdd00',
    text: '#0b0c0c',
    edge: '#0b0c0c',
    width: 3,
  },
  /** M3 shape scale adapted to GOV.UK restraint. Values in px. */
  shape: {
    none: 0,
    control: 4,
    card: 8,
    cardLarge: 12,
    dialog: 12,
    full: 9999,
  },
  /** 4px base grid. Values in px. */
  spacing: {
    unit: 4,
    0: 0,
    1: 4,
    2: 8,
    3: 12,
    4: 16,
    5: 20,
    6: 24,
    8: 32,
    10: 40,
    12: 48,
    15: 60,
  },
  /** Minimum interactive target size in px (WCAG 2.5.8 and GOV.UK guidance). */
  target: {
    minimum: 44,
  },
  typography: {
    fontFamily: '"Lato", "Helvetica Neue", Helvetica, Arial, sans-serif',
    monospaceFamily:
      'ui-monospace, "SFMono-Regular", Menlo, Consolas, "Liberation Mono", monospace',
    htmlFontSize: 16,
    weight: { regular: 400, bold: 700 },
    /** Sizes in px. Headings use sentence case. */
    size: {
      xs: 12,
      sm: 14,
      body: 16,
      lead: 19,
      h6: 16,
      h5: 19,
      h4: 22,
      h3: 24,
      h2: 30,
      h1: 36,
    },
    lineHeight: { tight: 1.2, body: 1.5 },
  },
  /** Restrained elevation: 1px outlines first, soft ambient shadow only for overlays. */
  elevation: {
    level0: 'none',
    level1: '0 1px 2px rgb(0 0 0 / 0.06)',
    level2: '0 2px 6px rgb(0 0 0 / 0.10)',
    level3: '0 8px 24px rgb(0 0 0 / 0.16)',
  },
  motion: {
    durationShort: 150,
    durationMedium: 250,
    easing: 'cubic-bezier(0.2, 0, 0, 1)',
  },
} as const;

/** Type of {@link brandTokens}. */
export type BrandTokens = typeof brandTokens;
