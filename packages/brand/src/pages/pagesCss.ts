import { brandTokensFor } from '../tokens/brandTokens';
import type { BrandModeColors } from '../tokens/brandTokens';

/**
 * The Lato files the public pages load, as they are named in
 * `@fontsource/lato/files`: the same three the app bundles (../fonts.ts).
 * They are copied to the app's `public/fonts/`.
 */
export const pagesFontFiles = [
  { file: 'lato-latin-400-normal.woff2', weight: 400, style: 'normal' },
  { file: 'lato-latin-400-italic.woff2', weight: 400, style: 'italic' },
  { file: 'lato-latin-700-normal.woff2', weight: 700, style: 'normal' },
] as const;

const rem = (px: number) => `${px / 16}rem`;

/** The colours a page needs, as custom properties, for one colour scheme. */
function colourVariables(c: BrandModeColors, page: string, indent: string) {
  return [
    `--page: ${page};`,
    `--text: ${c.onSurface};`,
    `--muted: ${c.onSurfaceVariant};`,
    `--link: ${c.link.default};`,
    `--link-hover: ${c.link.hover};`,
    `--link-visited: ${c.link.visited};`,
    `--header: ${c.navigation.background};`,
    `--on-header: ${c.navigation.selectedText};`,
    `--accent: ${c.header.accent};`,
    `--border: ${c.outlineVariant};`,
    `--code: ${c.surfaceContainer};`,
  ]
    .map(line => indent + line)
    .join('\n');
}

/**
 * The app's type for a static page that has a design of its own, such as a
 * figure: the Lato files, and the two font stacks as custom properties. The
 * app's `public/fonts/type.css` is this text.
 */
export function typeCss(): string {
  const { typography } = brandTokensFor(null);
  const fonts = pagesFontFiles
    .map(
      ({ file, weight: fontWeight, style }) => `@font-face {
  font-family: 'Lato';
  font-style: ${style};
  font-weight: ${fontWeight};
  font-display: swap;
  src: url('/fonts/${file}') format('woff2');
}`,
    )
    .join('\n');
  return `/* Generated from the brand tokens (packages/brand/src/pages/pagesCss.ts). */
${fonts}
:root {
  --portal-font: ${typography.fontFamily};
  --portal-mono: ${typography.monospaceFamily};
}
`;
}

/**
 * The stylesheet of the public pages (privacy, cookies, guides, sitemap),
 * which are plain HTML outside the app. It is written from the same tokens
 * as the app's theme, in the default preset: the same Lato, the same sizes,
 * weights and line heights, the same colour roles, links and focus. The
 * app's `public/pages.css` is this text; a test fails when the two differ.
 */
export function pagesCss(): string {
  const { color, typography, spacing, focus, shape } = brandTokensFor(null);
  const { size, weight, lineHeight } = typography;

  return `/*
 * Shared by the public pages: privacy, cookies, guides and sitemap.
 * Generated from the brand tokens (packages/brand/src/pages/pagesCss.ts):
 * change it there, then run
 *   UPDATE_PUBLIC_PAGES=1 yarn workspace app test src/publicPages.test.ts
 */
${typeCss().trimEnd()}
:root {
  color-scheme: light dark;
${colourVariables(color.light, color.light.surfaceContainerLow, '  ')}
}
@media (prefers-color-scheme: dark) {
  :root {
${colourVariables(color.dark, color.dark.surface, '    ')}
  }
}
body {
  margin: 0;
  background: var(--page);
  color: var(--text);
  font-family: ${typography.fontFamily};
  font-size: ${rem(size.body)};
  line-height: ${lineHeight.body};
  overflow-wrap: break-word;
}
header {
  background: var(--header);
  padding: ${spacing[4]}px ${spacing[6]}px;
}
header a {
  color: var(--on-header);
  font-size: ${rem(size.lead)};
  font-weight: ${weight.bold};
}
header a:hover,
header a:visited {
  color: var(--on-header);
}
main {
  max-width: 44rem;
  margin: 0 auto;
  padding: ${spacing[10]}px ${spacing[6]}px ${spacing[12]}px;
}
h1,
h2,
h3 {
  font-weight: ${weight.bold};
  line-height: ${lineHeight.tight};
}
h1 {
  font-size: ${rem(size.h1)};
  margin: 0 0 ${spacing[3]}px;
}
/* The rule under the page's title, as on the sign-in page. */
h1::after {
  content: '';
  display: block;
  width: 64px;
  height: 4px;
  margin-top: ${spacing[4]}px;
  background: var(--accent);
}
h2 {
  font-size: ${rem(size.h2)};
  margin: ${spacing[10]}px 0 ${spacing[2]}px;
}
h3 {
  font-size: ${rem(size.h3)};
  margin: ${spacing[6]}px 0 ${spacing[2]}px;
}
p,
ul,
ol,
table {
  margin: 0 0 ${spacing[4]}px;
}
li {
  margin: 0 0 ${spacing[1]}px;
}
.lead {
  font-size: ${rem(size.lead)};
}
.updated,
.note,
.pages code {
  color: var(--muted);
}
.updated {
  font-size: ${rem(size.sm)};
}
code {
  font-family: ${typography.monospaceFamily};
  font-size: 0.875em;
  padding: 0 ${spacing[1]}px;
  border-radius: ${shape.control}px;
  background: var(--code);
  overflow-wrap: anywhere;
}
a {
  color: var(--link);
  text-decoration: underline;
  text-decoration-thickness: max(1px, 0.0625rem);
  text-underline-offset: 0.15em;
}
a:visited {
  color: var(--link-visited);
}
a:hover {
  color: var(--link-hover);
  text-decoration-thickness: max(3px, 0.1875rem);
}
a:focus-visible {
  outline: ${focus.width}px solid transparent;
  color: ${focus.text};
  background-color: ${focus.color};
  box-shadow: 0 -2px ${focus.color}, 0 4px ${focus.edge};
  text-decoration: none;
}
table {
  border-collapse: collapse;
  width: 100%;
}
th,
td {
  text-align: left;
  vertical-align: top;
  padding: ${spacing[2]}px ${spacing[4]}px ${spacing[2]}px 0;
  border-bottom: 1px solid var(--border);
}
th {
  font-weight: ${weight.bold};
}
/* Lists of pages: the name, then its address. */
.pages {
  list-style: none;
  padding: 0;
}
.pages li {
  padding: ${spacing[2]}px 0;
  margin: 0;
  border-bottom: 1px solid var(--border);
}
.pages ul {
  list-style: none;
  margin: ${spacing[2]}px 0 0;
  padding: 0 0 0 ${spacing[6]}px;
}
.pages ul li:last-child {
  border-bottom: 0;
  padding-bottom: 0;
}
footer {
  border-top: 1px solid var(--border);
  font-size: ${rem(size.sm)};
}
footer nav {
  max-width: 44rem;
  margin: 0 auto;
  padding: ${spacing[6]}px ${spacing[6]}px ${spacing[10]}px;
}
footer ul {
  list-style: none;
  display: flex;
  flex-wrap: wrap;
  gap: ${spacing[2]}px ${spacing[6]}px;
  margin: 0;
  padding: 0;
}
footer li {
  margin: 0;
}
footer a[aria-current='page'] {
  color: var(--text);
  font-weight: ${weight.bold};
}
/* On a narrow screen each table row becomes a block, cell under cell. */
@media (max-width: 40rem) {
  thead {
    position: absolute;
    width: 1px;
    height: 1px;
    overflow: hidden;
    clip-path: inset(50%);
    white-space: nowrap;
  }
  tr,
  th,
  td {
    display: block;
  }
  tr {
    padding: ${spacing[2]}px 0;
    border-bottom: 1px solid var(--border);
  }
  th,
  td {
    padding: 2px 0;
    border-bottom: 0;
  }
  td[data-label]::before {
    content: attr(data-label) ': ';
    font-weight: ${weight.bold};
  }
}
`;
}
