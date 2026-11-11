import { presetIds, presetPalettes } from './palette.generated';
import type { M3Scheme, PresetId, PresetPalette } from './palette.generated';
import { presets } from './presets';
import type { ShapeScale } from './presets';

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

const WHITE = '#ffffff';

function lightColors({
  seeds,
  schemes,
  tonalPalettes: tone,
}: PresetPalette): BrandModeColors {
  return {
    ...schemes.light,
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
        text: schemes.light.error,
        container: schemes.light.errorContainer,
        onContainer: schemes.light.onErrorContainer,
        border: schemes.light.error,
        solid: tone.error[40],
        onSolid: tone.error[100],
      },
      info: {
        text: schemes.light.primary,
        container: schemes.light.primaryContainer,
        onContainer: schemes.light.onPrimaryContainer,
        border: schemes.light.primary,
        solid: seeds.primary,
        onSolid: WHITE,
      },
    },
    navigation: {
      background: seeds.secondary,
      text: tone.secondary[90],
      selectedText: WHITE,
      indicator: tone.primary[80],
      hoverBackground: tone.secondary[30],
      submenuBackground: tone.secondary[20],
    },
    link: {
      default: schemes.light.primary,
      hover: tone.primary[20],
      visited: schemes.light.tertiary,
    },
    header: {
      background: seeds.secondary,
      text: WHITE,
      accent: tone.primary[70],
    },
  };
}

function darkColors({
  seeds,
  schemes,
  tonalPalettes: tone,
}: PresetPalette): BrandModeColors {
  return {
    ...schemes.dark,
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
        text: schemes.dark.error,
        container: schemes.dark.errorContainer,
        onContainer: schemes.dark.onErrorContainer,
        border: tone.error[70],
        solid: tone.error[40],
        onSolid: tone.error[100],
      },
      info: {
        text: schemes.dark.primary,
        container: schemes.dark.primaryContainer,
        onContainer: schemes.dark.onPrimaryContainer,
        border: tone.primary[70],
        solid: seeds.primary,
        onSolid: WHITE,
      },
    },
    navigation: {
      background: tone.secondary[10],
      text: tone.secondary[90],
      selectedText: WHITE,
      indicator: tone.primary[80],
      hoverBackground: tone.secondary[20],
      submenuBackground: tone.secondary[17],
    },
    link: {
      default: schemes.dark.primary,
      hover: tone.primary[90],
      visited: schemes.dark.tertiary,
    },
    header: {
      background: tone.secondary[20],
      text: WHITE,
      accent: tone.primary[80],
    },
  };
}

/**
 * Tokens every preset shares: focus, spacing, type, elevation and motion.
 * Interaction and accessibility rules follow the GOV.UK Design System
 * (WCAG 2.2 AA, yellow focus, 44px targets).
 */
const foundation = {
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

/**
 * Brand tokens for one preset: the single source of truth for colour, shape,
 * spacing, typography and focus across MUI v4/v5, Backstage UI and TechDocs.
 * Colour roles are Material Design 3 roles generated from the preset's seeds
 * (see scripts/generate-palette.mjs).
 */
export type BrandTokens = typeof foundation & {
  preset: PresetId;
  palettes: PresetPalette['tonalPalettes'];
  color: Record<BrandMode, BrandModeColors>;
  /** Corner radii in px. */
  shape: ShapeScale;
};

/** The preset used until an administrator chooses one. */
export const DEFAULT_PRESET: PresetId = presetIds[0];

/** `id` when it names a preset, otherwise the default preset. */
export function resolvePresetId(id?: string | null): PresetId {
  return presetIds.find(known => known === id) ?? DEFAULT_PRESET;
}

const built = new Map<PresetId, BrandTokens>();

/** Tokens for a preset. An unknown or missing id gives the default preset. */
export function brandTokensFor(preset?: string | null): BrandTokens {
  const id = resolvePresetId(preset);
  let tokens = built.get(id);
  if (!tokens) {
    const palette = presetPalettes[id];
    tokens = {
      ...foundation,
      preset: id,
      palettes: palette.tonalPalettes,
      color: { light: lightColors(palette), dark: darkColors(palette) },
      shape: presets[id].shape,
    };
    built.set(id, tokens);
  }
  return tokens;
}
