#!/usr/bin/env node
/*
 * Generates src/tokens/palette.generated.ts: for every theme preset, the
 * Material Design 3 colour roles (light and dark) and tonal palettes derived
 * from that preset's three seed colours.
 *
 * To add a preset: add it to PRESETS below, describe it in
 * src/tokens/presets.ts, then run
 *   yarn workspace @internal/brand generate:palette
 * The contrast tests check every preset against WCAG 2.2 AA.
 */
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  argbFromHex,
  hexFromArgb,
  DynamicScheme,
  Hct,
  MaterialDynamicColors,
  SchemeTonalSpot,
  TonalPalette,
} from '@material/material-color-utilities';

// Variant is not exported from the package entry point; read it from the
// stock tonal-spot scheme so role tone mapping follows the M3 baseline.
const TONAL_SPOT = new SchemeTonalSpot(Hct.fromInt(0xff000000), false, 0)
  .variant;

/**
 * Theme presets. Each has three seeds:
 * - primary: actions, links and focus-independent accents. White text must
 *   reach 4.5:1 on it, because it also fills the "info" banner.
 * - secondary: the sidebar and page header surface, so it has to be dark.
 * - tertiary: visited links and the occasional contrasting accent.
 * The first preset is the default, and carries no organisation's identity.
 */
const PRESETS = [
  {
    id: 'neutral',
    primary: '#3f4a5a',
    secondary: '#1f2933',
    tertiary: '#5a4a6a',
  },
  {
    id: 'harbour',
    primary: '#005399',
    secondary: '#004149',
    tertiary: '#171695',
  },
  {
    id: 'forest',
    primary: '#1f6b45',
    secondary: '#173d2c',
    tertiary: '#5c5a1e',
  },
  { id: 'plum', primary: '#6a2c91', secondary: '#36204a', tertiary: '#a02c5a' },
  {
    id: 'ember',
    primary: '#a8401c',
    secondary: '#40241a',
    tertiary: '#7a5200',
  },
  {
    id: 'civic',
    primary: '#1d70b8',
    secondary: '#0b0c0c',
    tertiary: '#4c2c92',
  },
  {
    id: 'baseline',
    primary: '#6750a4',
    secondary: '#2b2440',
    tertiary: '#7d5260',
  },
];

/**
 * Status source colours. Hues follow the GOV.UK Design System conventions
 * (success green, warning orange); M3 tones are then chosen per role so every
 * text/surface pair meets WCAG 2.2 AA.
 */
const STATUS = {
  success: '#00703c',
  warning: '#f47738',
};

const TONES = [
  0, 4, 5, 6, 10, 12, 17, 20, 22, 24, 25, 30, 35, 40, 50, 60, 70, 80, 87, 90,
  92, 94, 95, 96, 98, 99, 100,
];

const ROLES = [
  'primary',
  'onPrimary',
  'primaryContainer',
  'onPrimaryContainer',
  'primaryFixed',
  'primaryFixedDim',
  'onPrimaryFixed',
  'onPrimaryFixedVariant',
  'secondary',
  'onSecondary',
  'secondaryContainer',
  'onSecondaryContainer',
  'secondaryFixed',
  'secondaryFixedDim',
  'onSecondaryFixed',
  'onSecondaryFixedVariant',
  'tertiary',
  'onTertiary',
  'tertiaryContainer',
  'onTertiaryContainer',
  'tertiaryFixed',
  'tertiaryFixedDim',
  'onTertiaryFixed',
  'onTertiaryFixedVariant',
  'error',
  'onError',
  'errorContainer',
  'onErrorContainer',
  'background',
  'onBackground',
  'surface',
  'surfaceDim',
  'surfaceBright',
  'surfaceContainerLowest',
  'surfaceContainerLow',
  'surfaceContainer',
  'surfaceContainerHigh',
  'surfaceContainerHighest',
  'onSurface',
  'surfaceVariant',
  'onSurfaceVariant',
  'outline',
  'outlineVariant',
  'inverseSurface',
  'inverseOnSurface',
  'inversePrimary',
  'surfaceTint',
  'shadow',
  'scrim',
];

const STATUS_PALETTES = {
  success: TonalPalette.fromInt(argbFromHex(STATUS.success)),
  warning: TonalPalette.fromInt(argbFromHex(STATUS.warning)),
};

function tonal(palette) {
  return Object.fromEntries(TONES.map(t => [t, hexFromArgb(palette.tone(t))]));
}

function buildPreset({ primary, secondary, tertiary }) {
  const seed = Hct.fromInt(argbFromHex(primary));
  const second = Hct.fromInt(argbFromHex(secondary));
  const third = Hct.fromInt(argbFromHex(tertiary));
  const palettes = {
    // Full source chroma keeps the primary recognisably the seed colour.
    primary: TonalPalette.fromHueAndChroma(seed.hue, seed.chroma),
    secondary: TonalPalette.fromHueAndChroma(second.hue, second.chroma),
    tertiary: TonalPalette.fromHueAndChroma(
      third.hue,
      Math.min(third.chroma, 48),
    ),
    // Calm, low-chroma neutrals tinted towards the seed hue.
    neutral: TonalPalette.fromHueAndChroma(seed.hue, Math.min(seed.chroma, 4)),
    neutralVariant: TonalPalette.fromHueAndChroma(
      seed.hue,
      Math.min(seed.chroma, 8),
    ),
  };
  const makeScheme = isDark =>
    new DynamicScheme({
      sourceColorArgb: seed.toInt(),
      variant: TONAL_SPOT,
      contrastLevel: 0,
      isDark,
      primaryPalette: palettes.primary,
      secondaryPalette: palettes.secondary,
      tertiaryPalette: palettes.tertiary,
      neutralPalette: palettes.neutral,
      neutralVariantPalette: palettes.neutralVariant,
    });
  const roles = isDark => {
    const scheme = makeScheme(isDark);
    const out = {};
    for (const role of ROLES) {
      out[role] = hexFromArgb(MaterialDynamicColors[role].getArgb(scheme));
    }
    if (!isDark) {
      // The M3 baseline puts the light primary at tone 40. A darker seed is
      // used at its own tone instead, so the primary action colour is the
      // seed itself and white text on it has more contrast.
      const pinned = Math.min(40, Math.max(25, Math.round(seed.tone)));
      out.primary = hexFromArgb(palettes.primary.tone(pinned));
      out.surfaceTint = out.primary;
    }
    return out;
  };
  return {
    seeds: { primary, secondary, tertiary },
    tonalPalettes: {
      primary: tonal(palettes.primary),
      secondary: tonal(palettes.secondary),
      tertiary: tonal(palettes.tertiary),
      neutral: tonal(palettes.neutral),
      neutralVariant: tonal(palettes.neutralVariant),
      error: tonal(makeScheme(false).errorPalette),
      success: tonal(STATUS_PALETTES.success),
      warning: tonal(STATUS_PALETTES.warning),
    },
    schemes: { light: roles(false), dark: roles(true) },
  };
}

const output = Object.fromEntries(
  PRESETS.map(preset => [preset.id, buildPreset(preset)]),
);

const banner = `/*
 * GENERATED FILE: do not edit by hand.
 * Source: packages/brand/scripts/generate-palette.mjs
 * Library: @material/material-color-utilities (Material Design 3 HCT / DynamicScheme)
 */
`;

const body = `${banner}
/** Material Design 3 colour role names emitted by the generator. */
export type M3Role = ${ROLES.map(r => `'${r}'`).join(' | ')};

/** A full set of Material Design 3 colour roles. */
export type M3Scheme = Record<M3Role, string>;

/** Tonal palette keyed by HCT tone (0 to 100). */
export type TonalPaletteHex = Record<${TONES.join(' | ')}, string>;

/** Ids of the theme presets, default first. */
export const presetIds = ${JSON.stringify(PRESETS.map(p => p.id))} as const;

/** Id of a theme preset. */
export type PresetId = (typeof presetIds)[number];

/** Everything generated for one preset. */
export interface PresetPalette {
  seeds: { primary: string; secondary: string; tertiary: string };
  tonalPalettes: Record<
    'primary' | 'secondary' | 'tertiary' | 'neutral' | 'neutralVariant' | 'error' | 'success' | 'warning',
    TonalPaletteHex
  >;
  schemes: { light: M3Scheme; dark: M3Scheme };
}

export const presetPalettes: Record<PresetId, PresetPalette> = ${JSON.stringify(
  output,
  null,
  2,
)};
`;

const target = fileURLToPath(
  new URL('../src/tokens/palette.generated.ts', import.meta.url),
);
writeFileSync(target, body);
process.stdout.write(`Wrote ${target}\n`);
