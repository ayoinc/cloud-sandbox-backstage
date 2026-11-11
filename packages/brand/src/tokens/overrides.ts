import { brandTokensFor } from './brandTokens';
import type { BrandMode, BrandModeColors } from './brandTokens';
import { contrastRatio } from './contrast';

/**
 * Runtime overrides an administrator can apply on top of the brand defaults
 * (for example from the branding-settings backend). `null` or missing values
 * keep the default.
 */
export interface BrandColorOverrides {
  /** Theme preset id. An unknown id gives the default preset. */
  preset?: string | null;
  /** Replacement primary colour as a 6-digit hex string. */
  primaryColor?: string | null;
}

const HEX = /^#[0-9a-f]{6}$/i;
const TEXT_AA = 4.5;

/**
 * Returns the colours of the chosen preset for `mode`, with the
 * administrator's primary colour applied when one is set.
 *
 * An override primary gets whichever of white or the mode's on-surface colour
 * contrasts more with it, so filled buttons always meet AA. The override is
 * also used for links only when it reaches 4.5:1 on the page surface;
 * otherwise links keep the brand link colour.
 */
export function resolveBrandColors(
  mode: BrandMode,
  overrides?: BrandColorOverrides,
): BrandModeColors {
  const base = brandTokensFor(overrides?.preset).color[mode];
  const primary = overrides?.primaryColor?.trim();
  if (!primary || !HEX.test(primary)) {
    return base;
  }
  const candidates = ['#ffffff', base.onSurface, '#000000'];
  const onPrimary = candidates.reduce((best, candidate) =>
    contrastRatio(candidate, primary) > contrastRatio(best, primary)
      ? candidate
      : best,
  );
  const linkable =
    contrastRatio(primary, base.surface) >= TEXT_AA &&
    contrastRatio(primary, base.surfaceContainerLowest) >= TEXT_AA;
  return {
    ...base,
    primary: primary.toLowerCase(),
    onPrimary,
    surfaceTint: primary.toLowerCase(),
    link: linkable
      ? { ...base.link, default: primary.toLowerCase() }
      : base.link,
  };
}
