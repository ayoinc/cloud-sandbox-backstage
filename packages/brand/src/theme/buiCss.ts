import { brandTokens } from '../tokens/brandTokens';
import type {
  BrandMode,
  BrandModeColors,
  StatusName,
} from '../tokens/brandTokens';
import { resolveBrandColors } from '../tokens/overrides';
import type { BrandColorOverrides } from '../tokens/overrides';

/** Selector prefix of the Backstage toast root (CSS module class `Toast_toast__<hash>`). */
const TOAST = "[class*='Toast_toast__']";

/** M3 state layer: overlay `colour` on `base` at the given opacity. */
function stateLayer(base: string, colour: string, opacity: number): string {
  return `color-mix(in srgb, ${colour} ${Math.round(opacity * 100)}%, ${base})`;
}

function px(value: number): string {
  return `${value / 16}rem`;
}

/**
 * Backstage UI (`--bui-*`) custom properties for one mode, derived from
 * {@link brandTokens}. Token names verified against @backstage/ui 0.19 styles.css.
 */
export function buiVariables(
  mode: BrandMode,
  overrides?: BrandColorOverrides,
): Record<string, string> {
  const c: BrandModeColors = resolveBrandColors(mode, overrides);
  const { typography, shape, focus } = brandTokens;
  const isDark = mode === 'dark';

  const bg = isDark
    ? {
        app: c.surface,
        n1: c.surfaceContainerLow,
        n2: c.surfaceContainer,
        n3: c.surfaceContainerHigh,
        n4: c.surfaceContainerHighest,
      }
    : {
        app: c.surfaceContainerLow,
        n1: c.surfaceContainerLowest,
        n2: c.surfaceContainer,
        n3: c.surfaceContainerLowest,
        n4: c.surfaceContainer,
      };

  const vars: Record<string, string> = {
    // Typography
    '--bui-font-regular': typography.fontFamily,
    '--bui-font-monospace': typography.monospaceFamily,
    '--bui-font-weight-regular': String(typography.weight.regular),
    '--bui-font-weight-bold': String(typography.weight.bold),

    // Shape: 4px controls, 8 to 12px cards, full-round chips
    '--bui-radius-1': px(2),
    '--bui-radius-2': px(shape.control),
    '--bui-radius-3': px(shape.card),
    '--bui-radius-4': px(shape.cardLarge),
    '--bui-radius-5': px(16),
    '--bui-radius-6': px(20),
    '--bui-radius-full': `${shape.full}px`,

    // Base colours
    '--bui-black': '#000000',
    '--bui-white': '#ffffff',
    '--bui-ring': focus.color,
    '--bui-scrollbar': `color-mix(in srgb, ${c.outline} 24%, transparent)`,
    '--bui-scrollbar-thumb': c.outline,

    // Surfaces (M3 surface-container levels). Interaction overlays
    // (--bui-bg-neutral-N-hover/pressed/disabled) are deprecated; BUI's
    // translucent defaults already layer correctly over these surfaces.
    '--bui-bg-app': bg.app,
    '--bui-bg-neutral-1': bg.n1,
    '--bui-bg-neutral-2': bg.n2,
    '--bui-bg-neutral-3': bg.n3,
    '--bui-bg-neutral-4': bg.n4,

    // Foreground
    '--bui-fg-primary': c.onSurface,
    '--bui-fg-secondary': c.onSurfaceVariant,
    '--bui-fg-disabled': `color-mix(in srgb, ${c.onSurface} 38%, transparent)`,

    // Borders: 1px outline-variant for structure, outline for controls
    '--bui-border-1': c.outlineVariant,
    '--bui-border-2': c.outline,

    // Accent (primary)
    '--bui-accent-bg': c.primary,
    '--bui-accent-bg-hover': stateLayer(c.primary, c.onPrimary, 0.12),
    '--bui-accent-bg-disabled': `color-mix(in srgb, ${c.onSurface} 12%, transparent)`,
    '--bui-accent-fg': c.onPrimary,
    '--bui-accent-fg-disabled': `color-mix(in srgb, ${c.onSurface} 38%, transparent)`,
  };

  // Status families (current BUI semantic tokens), all mapped to the same
  // AA-checked brand status roles.
  const families: Array<[StatusName, string]> = [
    ['success', 'positive'],
    ['danger', 'negative'],
    ['warning', 'warning'],
    ['info', 'announcement'],
  ];
  for (const [status, family] of families) {
    const s = c.status[status];
    Object.assign(vars, {
      [`--bui-fg-${family}`]: s.text,
      [`--bui-${family}-bg`]: s.solid,
      [`--bui-${family}-bg-hover`]: stateLayer(s.solid, s.onSolid, 0.12),
      [`--bui-${family}-bg-disabled`]: s.solid,
      [`--bui-${family}-bg-subdued`]: s.container,
      [`--bui-${family}-bg-subdued-hover`]: stateLayer(
        s.container,
        s.onContainer,
        0.08,
      ),
      [`--bui-${family}-bg-subdued-disabled`]: s.container,
      [`--bui-${family}-border`]: s.border,
      [`--bui-${family}-fg`]: s.onSolid,
      [`--bui-${family}-fg-disabled`]: `color-mix(in srgb, ${s.onSolid} 60%, ${s.solid})`,
      [`--bui-${family}-fg-subdued`]: s.onContainer,
      [`--bui-${family}-fg-subdued-disabled`]: `color-mix(in srgb, ${s.onContainer} 60%, ${s.container})`,
    });
  }

  return vars;
}

/** Current BUI foreground token for each brand status. */
const STATUS_FG: Record<StatusName, string> = {
  success: '--bui-fg-positive',
  danger: '--bui-fg-negative',
  warning: '--bui-fg-warning',
  info: '--bui-fg-announcement',
};

/**
 * Variables re-scoped onto a Backstage toast so each status renders as a solid,
 * high-visibility banner (GOV.UK notification style): status colour fill,
 * status icon and title text, all in the AA-checked on-solid colour.
 */
export function toastVariables(
  mode: BrandMode,
  status: StatusName,
): Record<string, string> {
  const s = brandTokens.color[mode].status[status];
  return {
    '--bui-bg-app': s.solid,
    '--bui-border-1': s.solid,
    '--bui-fg-primary': s.onSolid,
    '--bui-fg-secondary': s.onSolid,
    [STATUS_FG[status]]: s.onSolid,
    '--bui-ring': brandTokens.focus.color,
  };
}

function block(selector: string, vars: Record<string, string>): string {
  const body = Object.entries(vars)
    .map(([name, value]) => `  ${name}: ${value};`)
    .join('\n');
  return `${selector} {\n${body}\n}`;
}

/** GOV.UK-style focus treatment shared by MUI, Backstage UI and plain HTML. */
function focusCss(): string {
  const { color, text, edge, width } = brandTokens.focus;
  return `
body :focus-visible,
body [data-focus-visible] {
  outline: ${width}px solid ${color};
  outline-offset: 0;
  box-shadow: 0 0 0 ${width * 2}px ${edge};
}
body a:focus-visible {
  outline: ${width}px solid transparent;
  background-color: ${color};
  box-shadow: 0 -2px ${color}, 0 4px ${edge};
  text-decoration: none;
}
body a:focus-visible,
body a:focus-visible * {
  color: ${text} !important;
}
@media (forced-colors: active) {
  body :focus-visible,
  body [data-focus-visible] {
    outline: ${width}px solid CanvasText;
    box-shadow: none;
  }
}`;
}

/**
 * Component-level tweaks Backstage UI cannot express through tokens alone.
 * BUI component styles live in cascade layers, so the theme layer wins; the
 * toast module CSS is unlayered, so toast rules are unlayered with higher
 * specificity.
 */
function componentCss(): string {
  const { target, shape, elevation } = brandTokens;
  return `
@layer theme {
  [class*='bui-Button'][data-size='medium'] {
    min-height: ${target.minimum}px;
  }
  [class*='bui-Tag'][data-size],
  [class*='bui-Badge'] {
    border-radius: ${shape.full}px;
  }
}
${TOAST} [class*='Toast_surface__'] {
  box-shadow: ${elevation.level3};
}
${TOAST} [class*='Toast_closeButton__'] {
  min-width: 24px;
  min-height: 24px;
}
${TOAST} [class*='Toast_closeButton__']:hover {
  background-color: color-mix(in srgb, var(--bui-fg-primary) 16%, transparent);
}
${TOAST} [class*='Toast_closeButton__']:active {
  background-color: color-mix(in srgb, var(--bui-fg-primary) 24%, transparent);
}`;
}

/**
 * Complete stylesheet for the active brand theme. `mode` decides which values
 * apply on `:root` before Backstage writes the `data-theme-mode` attribute;
 * explicit light/dark blocks keep nested BUI mode switching on brand.
 */
export function buiThemeCss(
  mode: BrandMode,
  overrides?: BrandColorOverrides,
): string {
  const other: BrandMode = mode === 'light' ? 'dark' : 'light';
  const toastBlocks = (m: BrandMode, scope: string) =>
    (['success', 'warning', 'danger', 'info'] as StatusName[])
      .map(status =>
        block(
          `${scope}${TOAST}[data-status='${status}']`,
          toastVariables(m, status),
        ),
      )
      .join('\n');

  return [
    '@layer tokens, base, components, theme, utilities;',
    '@layer theme {',
    block(':root', buiVariables(mode, overrides)),
    block(`[data-theme-mode='${other}']`, buiVariables(other, overrides)),
    block(`[data-theme-mode='${mode}']`, buiVariables(mode, overrides)),
    toastBlocks(mode, ''),
    toastBlocks(other, `[data-theme-mode='${other}'] `),
    '}',
    componentCss(),
    focusCss(),
  ].join('\n');
}
