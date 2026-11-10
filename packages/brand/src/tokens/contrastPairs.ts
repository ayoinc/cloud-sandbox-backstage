import { brandTokens } from './brandTokens';
import type { BrandMode, StatusName } from './brandTokens';
import { blend, contrastRatio } from './contrast';

/** A foreground/background pair with its WCAG 2.2 AA minimum. */
export interface ContrastPair {
  name: string;
  foreground: string;
  background: string;
  /** 4.5 for text, 3 for non-text indicators (WCAG 1.4.3 / 1.4.11). */
  minimum: number;
  ratio: number;
}

const TEXT = 4.5;
const NON_TEXT = 3;

/** Opacity BUI toasts apply to description text. */
const TOAST_DESCRIPTION_OPACITY = 0.9;

/**
 * Every text/surface and indicator/surface pairing the brand themes use, with
 * its measured contrast ratio. Used by tests and the contrast report.
 */
export function contrastPairs(mode: BrandMode): ContrastPair[] {
  const c = brandTokens.color[mode];
  const { focus } = brandTokens;
  const pairs: Array<Omit<ContrastPair, 'ratio'>> = [];
  const add = (
    name: string,
    foreground: string,
    background: string,
    minimum: number,
  ) => pairs.push({ name, foreground, background, minimum });

  const surfaces = {
    surface: c.surface,
    surfaceContainerLowest: c.surfaceContainerLowest,
    surfaceContainerLow: c.surfaceContainerLow,
    surfaceContainer: c.surfaceContainer,
    surfaceContainerHigh: c.surfaceContainerHigh,
    surfaceContainerHighest: c.surfaceContainerHighest,
  };

  for (const [surfaceName, surface] of Object.entries(surfaces)) {
    add(`onSurface on ${surfaceName}`, c.onSurface, surface, TEXT);
    add(
      `onSurfaceVariant on ${surfaceName}`,
      c.onSurfaceVariant,
      surface,
      TEXT,
    );
    add(`primary (link) on ${surfaceName}`, c.link.default, surface, TEXT);
    add(`outline on ${surfaceName}`, c.outline, surface, NON_TEXT);
  }
  add('link hover on surface', c.link.hover, c.surface, TEXT);
  add('link visited on surface', c.link.visited, c.surface, TEXT);

  add('onPrimary on primary', c.onPrimary, c.primary, TEXT);
  add(
    'onPrimaryContainer on primaryContainer',
    c.onPrimaryContainer,
    c.primaryContainer,
    TEXT,
  );
  add('onSecondary on secondary', c.onSecondary, c.secondary, TEXT);
  add(
    'onSecondaryContainer on secondaryContainer',
    c.onSecondaryContainer,
    c.secondaryContainer,
    TEXT,
  );
  add('onTertiary on tertiary', c.onTertiary, c.tertiary, TEXT);
  add(
    'onTertiaryContainer on tertiaryContainer',
    c.onTertiaryContainer,
    c.tertiaryContainer,
    TEXT,
  );
  add('onError on error', c.onError, c.error, TEXT);
  add(
    'onErrorContainer on errorContainer',
    c.onErrorContainer,
    c.errorContainer,
    TEXT,
  );
  add(
    'inverseOnSurface on inverseSurface',
    c.inverseOnSurface,
    c.inverseSurface,
    TEXT,
  );
  add(
    'inversePrimary on inverseSurface',
    c.inversePrimary,
    c.inverseSurface,
    TEXT,
  );

  for (const name of ['success', 'warning', 'danger', 'info'] as StatusName[]) {
    const s = c.status[name];
    add(`${name} text on surface`, s.text, c.surface, TEXT);
    add(
      `${name} text on surfaceContainerLowest`,
      s.text,
      c.surfaceContainerLowest,
      TEXT,
    );
    add(
      `${name} text on surfaceContainerLow`,
      s.text,
      c.surfaceContainerLow,
      TEXT,
    );
    add(`${name} onContainer on container`, s.onContainer, s.container, TEXT);
    add(`${name} border on surface`, s.border, c.surface, NON_TEXT);
    add(`${name} solid toast title on solid`, s.onSolid, s.solid, TEXT);
    add(
      `${name} solid toast description on solid`,
      blend(s.onSolid, s.solid, TOAST_DESCRIPTION_OPACITY),
      s.solid,
      TEXT,
    );
  }

  add(
    'navigation text on navigation',
    c.navigation.text,
    c.navigation.background,
    TEXT,
  );
  add(
    'navigation selected on navigation',
    c.navigation.selectedText,
    c.navigation.background,
    TEXT,
  );
  add(
    'navigation text on hover',
    c.navigation.text,
    c.navigation.hoverBackground,
    TEXT,
  );
  add(
    'navigation text on submenu',
    c.navigation.text,
    c.navigation.submenuBackground,
    TEXT,
  );
  add(
    'navigation indicator on navigation',
    c.navigation.indicator,
    c.navigation.background,
    NON_TEXT,
  );
  add('header text on header', c.header.text, c.header.background, TEXT);
  add(
    'header accent on header',
    c.header.accent,
    c.header.background,
    NON_TEXT,
  );
  add('focus text on focus yellow', focus.text, focus.color, TEXT);

  const measured = pairs.map(p => ({
    ...p,
    ratio: contrastRatio(p.foreground, p.background),
  }));

  // Focus ring: yellow inner ring plus dark outer edge. At least one of the
  // two rings must reach 3:1 against every surface the ring can sit on.
  for (const [surfaceName, surface] of Object.entries(surfaces)) {
    const yellow = contrastRatio(focus.color, surface);
    const edge = contrastRatio(focus.edge, surface);
    const best = yellow >= edge ? focus.color : focus.edge;
    measured.push({
      name: `focus ring on ${surfaceName}`,
      foreground: best,
      background: surface,
      minimum: NON_TEXT,
      ratio: Math.max(yellow, edge),
    });
  }

  return measured;
}
