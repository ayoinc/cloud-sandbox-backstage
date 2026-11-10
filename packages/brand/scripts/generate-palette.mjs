#!/usr/bin/env node
/*
 * Generates src/tokens/palette.generated.ts: Material Design 3 colour roles
 * (light and dark) and tonal palettes derived from the Solirius Reply brand
 * colours sampled from the official logo artwork.
 *
 * Run with: yarn workspace @internal/brand generate:palette
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
const TONAL_SPOT = new SchemeTonalSpot(Hct.fromInt(0xff000000), false, 0).variant;

/**
 * Brand source colours.
 * - solirius blue: running figure and "SOLIRIUS" wordmark (sampled from logo PNG).
 * - reply teal: "REPLY" wordmark (sampled from logo PNG).
 * - solirius indigo: secondary palette colour published on solirius.com.
 */
const BRAND = {
  soliriusBlue: '#005399',
  replyTeal: '#004149',
  soliriusIndigo: '#171695',
};

/**
 * Status source colours. Hues follow the GOV.UK Design System conventions
 * (success green, warning orange); M3 tones are then chosen per role so every
 * text/surface pair meets WCAG 2.2 AA.
 */
const STATUS = {
  success: '#00703c',
  warning: '#f47738',
};

const TONES = [0, 4, 5, 6, 10, 12, 17, 20, 22, 24, 25, 30, 35, 40, 50, 60, 70, 80, 87, 90, 92, 94, 95, 96, 98, 99, 100];

const ROLES = [
  'primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer',
  'primaryFixed', 'primaryFixedDim', 'onPrimaryFixed', 'onPrimaryFixedVariant',
  'secondary', 'onSecondary', 'secondaryContainer', 'onSecondaryContainer',
  'secondaryFixed', 'secondaryFixedDim', 'onSecondaryFixed', 'onSecondaryFixedVariant',
  'tertiary', 'onTertiary', 'tertiaryContainer', 'onTertiaryContainer',
  'tertiaryFixed', 'tertiaryFixedDim', 'onTertiaryFixed', 'onTertiaryFixedVariant',
  'error', 'onError', 'errorContainer', 'onErrorContainer',
  'background', 'onBackground',
  'surface', 'surfaceDim', 'surfaceBright',
  'surfaceContainerLowest', 'surfaceContainerLow', 'surfaceContainer',
  'surfaceContainerHigh', 'surfaceContainerHighest',
  'onSurface', 'surfaceVariant', 'onSurfaceVariant',
  'outline', 'outlineVariant',
  'inverseSurface', 'inverseOnSurface', 'inversePrimary',
  'surfaceTint', 'shadow', 'scrim',
];

const seed = Hct.fromInt(argbFromHex(BRAND.soliriusBlue));
const teal = Hct.fromInt(argbFromHex(BRAND.replyTeal));
const indigo = Hct.fromInt(argbFromHex(BRAND.soliriusIndigo));

const palettes = {
  // Full source chroma keeps the primary recognisably "Solirius blue".
  primary: TonalPalette.fromHueAndChroma(seed.hue, seed.chroma),
  // Secondary carries the REPLY teal hue at its own chroma.
  secondary: TonalPalette.fromHueAndChroma(teal.hue, teal.chroma),
  // Tertiary carries the solirius.com indigo.
  tertiary: TonalPalette.fromHueAndChroma(indigo.hue, Math.min(indigo.chroma, 48)),
  // Calm, low-chroma neutrals tinted towards the seed hue.
  neutral: TonalPalette.fromHueAndChroma(seed.hue, 4),
  neutralVariant: TonalPalette.fromHueAndChroma(seed.hue, 8),
};

function makeScheme(isDark) {
  return new DynamicScheme({
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
}

function buildScheme(isDark) {
  const scheme = makeScheme(isDark);
  const roles = {};
  for (const role of ROLES) {
    roles[role] = hexFromArgb(MaterialDynamicColors[role].getArgb(scheme));
  }
  if (!isDark) {
    // Brand pin: the logo blue sits at HCT tone 35 of the primary palette.
    // M3 baseline uses tone 40; pinning to 35 makes the primary action colour
    // the exact Solirius blue and raises onPrimary contrast.
    roles.primary = hexFromArgb(palettes.primary.tone(35));
    roles.surfaceTint = roles.primary;
  }
  return roles;
}

function tonal(palette) {
  return Object.fromEntries(TONES.map(t => [t, hexFromArgb(palette.tone(t))]));
}

const errorPalette = makeScheme(false).errorPalette;

const output = {
  source: {
    ...BRAND,
    status: STATUS,
    hct: {
      soliriusBlue: { hue: +seed.hue.toFixed(2), chroma: +seed.chroma.toFixed(2), tone: +seed.tone.toFixed(2) },
      replyTeal: { hue: +teal.hue.toFixed(2), chroma: +teal.chroma.toFixed(2), tone: +teal.tone.toFixed(2) },
      soliriusIndigo: { hue: +indigo.hue.toFixed(2), chroma: +indigo.chroma.toFixed(2), tone: +indigo.tone.toFixed(2) },
    },
  },
  tonalPalettes: {
    primary: tonal(palettes.primary),
    secondary: tonal(palettes.secondary),
    tertiary: tonal(palettes.tertiary),
    neutral: tonal(palettes.neutral),
    neutralVariant: tonal(palettes.neutralVariant),
    error: tonal(errorPalette),
    success: tonal(TonalPalette.fromInt(argbFromHex(STATUS.success))),
    warning: tonal(TonalPalette.fromInt(argbFromHex(STATUS.warning))),
  },
  schemes: {
    light: buildScheme(false),
    dark: buildScheme(true),
  },
};

const banner = `/*
 * GENERATED FILE: do not edit by hand.
 * Source: packages/brand/scripts/generate-palette.mjs
 * Library: @material/material-color-utilities (Material Design 3 HCT / DynamicScheme)
 * Seed: Solirius blue ${BRAND.soliriusBlue}; secondary hue REPLY teal ${BRAND.replyTeal};
 * tertiary hue solirius.com indigo ${BRAND.soliriusIndigo}.
 */
`;

const body = `${banner}
/** Material Design 3 colour role names emitted by the generator. */
export type M3Role = ${ROLES.map(r => `'${r}'`).join(' | ')};

/** A full set of Material Design 3 colour roles. */
export type M3Scheme = Record<M3Role, string>;

/** Tonal palette keyed by HCT tone (0 to 100). */
export type TonalPaletteHex = Record<${TONES.join(' | ')}, string>;

export const m3Source = ${JSON.stringify(output.source, null, 2)} as const;

export const m3TonalPalettes: Record<
  'primary' | 'secondary' | 'tertiary' | 'neutral' | 'neutralVariant' | 'error' | 'success' | 'warning',
  TonalPaletteHex
> = ${JSON.stringify(output.tonalPalettes, null, 2)};

export const m3Schemes: { light: M3Scheme; dark: M3Scheme } = ${JSON.stringify(output.schemes, null, 2)};
`;

const target = fileURLToPath(new URL('../src/tokens/palette.generated.ts', import.meta.url));
writeFileSync(target, body);
process.stdout.write(`Wrote ${target}\n`);
