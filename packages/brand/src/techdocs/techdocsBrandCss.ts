import { brandTokensFor } from '../tokens/brandTokens';
import { resolveBrandColors } from '../tokens/overrides';
import type { BrandColorOverrides } from '../tokens/overrides';
import type { BrandMode, BrandTokens, StatusName } from '../tokens/brandTokens';

/** mkdocs-material admonition types grouped by brand status. */
const ADMONITIONS: Record<StatusName, string[]> = {
  info: [
    'note',
    'abstract',
    'summary',
    'tldr',
    'info',
    'todo',
    'question',
    'help',
    'faq',
    'example',
    'quote',
    'cite',
  ],
  success: ['tip', 'hint', 'important', 'success', 'check', 'done'],
  warning: ['warning', 'caution', 'attention'],
  danger: ['failure', 'fail', 'missing', 'danger', 'error', 'bug'],
};

/**
 * D2 draws a diagram in its theme's colours, named B1 to B6 (the theme
 * colour, dark to light) and AA/AB (two accents), on neutrals N1 to N7.
 * Mapping the theme names onto the preset's palettes makes every diagram in
 * the documentation take the portal's colours.
 *
 * The neutrals are left alone, in dark mode too: authors give shapes light
 * fills of their own and rely on the theme's dark text over them, so a
 * diagram stays a sheet of light paper, set on a card where the page is dark.
 */
function d2ThemeCss(
  mode: BrandMode,
  p: BrandTokens['palettes'],
  card: number,
): string {
  const colours: Record<string, string> = {
    B1: p.primary[35],
    B2: p.primary[35],
    B3: p.primary[90],
    B4: p.primary[90],
    B5: p.primary[95],
    B6: p.primary[98],
    AA2: p.secondary[40],
    AA4: p.secondary[95],
    AA5: p.secondary[98],
    AB4: p.tertiary[95],
    AB5: p.tertiary[98],
  };
  // D2 scopes its own rules to the diagram with one class, so these need
  // !important to win.
  const mapped = Object.entries(colours)
    .map(
      ([
        name,
        colour,
      ]) => `:host svg.d2-svg .fill-${name} { fill: ${colour} !important; }
:host svg.d2-svg .stroke-${name} { stroke: ${colour} !important; }
:host svg.d2-svg .color-${name} { color: ${colour} !important; }
:host svg.d2-svg .background-color-${name} { background-color: ${colour} !important; }`,
    )
    .join('\n');
  return mode === 'dark'
    ? `${mapped}
:host svg.d2-svg { border-radius: ${card}px; }`
    : mapped;
}

/**
 * Brand stylesheet for TechDocs content. It is written for the TechDocs
 * shadow root (`:host` scoped) and layers on top of the palette-driven
 * variables TechDocs already derives from the active MUI theme.
 */
export function techdocsBrandCss(
  mode: BrandMode,
  overrides?: BrandColorOverrides,
): string {
  const c = resolveBrandColors(mode, overrides);
  const tokens = brandTokensFor(overrides?.preset);
  const { typography, shape, focus } = tokens;

  const diagrams = d2ThemeCss(mode, tokens.palettes, shape.card);

  const admonitions = (Object.keys(ADMONITIONS) as StatusName[])
    .map(status => {
      const s = c.status[status];
      const types = ADMONITIONS[status];
      const boxes = types
        .map(
          t =>
            `:host .md-typeset .admonition.${t}, :host .md-typeset details.${t}`,
        )
        .join(',\n');
      const titles = types
        .map(
          t =>
            `:host .md-typeset .${t} > .admonition-title, :host .md-typeset .${t} > summary`,
        )
        .join(',\n');
      const icons = types
        .map(
          t =>
            `:host .md-typeset .${t} > .admonition-title::before, :host .md-typeset .${t} > summary::before`,
        )
        .join(',\n');
      return `${boxes} {
  border: 1px solid ${s.border};
  border-left-width: 4px;
}
${titles} {
  background-color: ${s.container};
  color: ${s.onContainer};
}
${icons} {
  background-color: ${s.onContainer};
}`;
    })
    .join('\n');

  return `
:host {
  --md-text-font: ${typography.fontFamily};
  --md-code-font: ${typography.monospaceFamily};
  --md-typeset-a-color: ${c.link.default};
  --md-code-bg-color: ${c.surfaceContainer};
  --md-code-fg-color: ${c.onSurface};
}
:host .md-typeset {
  font-family: ${typography.fontFamily};
  line-height: ${typography.lineHeight.body};
  color: ${c.onSurface};
}
:host .md-typeset h1,
:host .md-typeset h2,
:host .md-typeset h3,
:host .md-typeset h4,
:host .md-typeset h5,
:host .md-typeset h6 {
  font-family: ${typography.fontFamily};
  font-weight: ${typography.weight.bold};
  letter-spacing: normal;
  color: ${c.onSurface};
}
:host .md-typeset a {
  color: ${c.link.default};
  text-decoration: underline;
  text-decoration-thickness: max(1px, 0.0625rem);
  text-underline-offset: 0.15em;
}
:host .md-typeset a:visited {
  color: ${c.link.visited};
}
:host .md-typeset a:hover {
  color: ${c.link.hover};
  text-decoration-thickness: max(3px, 0.1875rem);
}
:host a:focus-visible {
  outline: ${focus.width}px solid transparent;
  color: ${focus.text};
  background-color: ${focus.color};
  box-shadow: 0 -2px ${focus.color}, 0 4px ${focus.edge};
  text-decoration: none;
}
:host :focus-visible:not(a) {
  outline: ${focus.width}px solid ${focus.color};
  outline-offset: 0;
  box-shadow: 0 0 0 ${focus.width * 2}px ${focus.edge};
}
:host .md-typeset code {
  border-radius: ${shape.control}px;
}
:host .md-typeset pre > code {
  border-radius: ${shape.card}px;
  border: 1px solid ${c.outlineVariant};
}
:host .md-typeset .admonition,
:host .md-typeset details {
  border-radius: ${shape.card}px;
  box-shadow: none;
}
:host .md-typeset table:not([class]) {
  border: 1px solid ${c.outlineVariant};
  border-radius: ${shape.card}px;
  box-shadow: none;
}
:host .md-typeset table:not([class]) th {
  background-color: ${c.surfaceContainer};
  color: ${c.onSurface};
}
:host .md-typeset table:not([class]) td,
:host .md-typeset table:not([class]) th {
  font-variant-numeric: tabular-nums;
}
${admonitions}
${diagrams}
`;
}
