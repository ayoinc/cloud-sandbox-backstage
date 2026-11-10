import type { LookTokens } from './kit';
import { brandTokens } from '../tokens/brandTokens';
import type { BrandMode } from '../tokens/brandTokens';

/**
 * The Solirius Reply look for Stageshow stages: the brand tokens mapped onto
 * the kit's (`--ss-*`), so a demo follows the portal's light and dark themes.
 * Colour roles come from the same M3 scheme the Backstage theme uses; the
 * `--ss-nav-*` tokens carry the sidebar's own roles for the scene's CSS.
 */
export function soliriusLook(mode: BrandMode): LookTokens {
  const c = brandTokens.color[mode];
  const { shape, typography } = brandTokens;
  const dark = mode === 'dark';
  // Cards sit on the page: white on the tinted page in light mode, one
  // surface step lighter than the page in dark mode.
  const card = dark ? c.surfaceContainerLow : c.surfaceContainerLowest;
  return {
    '--ss-canvas': c.background,
    '--ss-surface': card,
    '--ss-chrome': card,
    '--ss-raised': dark ? c.surfaceContainerHigh : c.surfaceContainerLowest,
    '--ss-line': c.outlineVariant,
    '--ss-line-faint': dark
      ? c.surfaceContainerHigh
      : c.surfaceContainerHighest,
    '--ss-text-strong': c.onSurface,
    '--ss-text': c.onSurfaceVariant,
    '--ss-text-faint': c.outline,
    '--ss-icon': c.onSurfaceVariant,
    '--ss-icon-faint': c.outlineVariant,
    '--ss-accent': c.primary,
    '--ss-accent-2': c.primary,
    // A soft ring round a focused field: the container tint in light mode; in
    // dark mode that role is a saturated blue, so a wash of the accent instead.
    '--ss-accent-soft': dark
      ? `color-mix(in srgb, ${c.primary} 22%, transparent)`
      : c.primaryContainer,
    '--ss-accent-text': c.link.default,
    '--ss-font': typography.fontFamily,
    '--ss-mono': typography.monospaceFamily,
    '--ss-radius-sm': `${shape.control}px`,
    '--ss-radius-md': `${shape.control}px`,
    '--ss-radius-lg': `${shape.card}px`,
    '--ss-radius-window': `${shape.cardLarge}px`,
    '--ss-radius-pill': `${shape.full}px`,
    '--ss-nav-bg': c.navigation.background,
    '--ss-nav-text': c.navigation.text,
    '--ss-nav-selected': c.navigation.selectedText,
    '--ss-nav-indicator': c.navigation.indicator,
    '--ss-nav-hover': c.navigation.hoverBackground,
    '--ss-on-accent': c.onPrimary,
  };
}
