// This test runs in Node and is about files on disk, which the app's own
// code may not touch.
/* eslint-disable no-restricted-imports */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
/* eslint-enable no-restricted-imports */
import { pagesCss, pagesFontFiles, typeCss } from '@internal/brand';

/**
 * The public pages (privacy, cookies, guides, sitemap) are plain HTML beside
 * the app, so they cannot use its theme. Their stylesheet and fonts are
 * written from the same brand tokens instead, and this test fails when they
 * are not what the tokens say, so the two cannot drift apart.
 *
 * To write them again after changing the tokens:
 *   UPDATE_PUBLIC_PAGES=1 yarn workspace app test src/publicPages.test.ts
 */
const PUBLIC = join(__dirname, '..', 'public');
const PAGES = ['privacy', 'cookies', 'guides', 'sitemap'];
const update = Boolean(process.env.UPDATE_PUBLIC_PAGES);

/** `path` under public/, written first when updating. */
function publicFile(path: string, wanted: Buffer): Buffer | undefined {
  const file = join(PUBLIC, path);
  if (update) {
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, wanted);
  }
  return existsSync(file) ? readFileSync(file) : undefined;
}

describe('public pages', () => {
  it.each([
    ['pages.css', pagesCss()],
    ['fonts/type.css', typeCss()],
  ])('%s is written from the brand tokens', (path, wanted) => {
    expect(publicFile(path, Buffer.from(wanted))?.toString()).toBe(wanted);
  });

  it.each(pagesFontFiles)(
    'load the Lato the app bundles: $file',
    ({ file }) => {
      const bundled = readFileSync(
        join(
          dirname(require.resolve('@fontsource/lato/package.json')),
          'files',
          file,
        ),
      );
      expect(publicFile(`fonts/${file}`, bundled)?.equals(bundled)).toBe(true);
    },
  );

  it.each(PAGES)('%s.html takes its look from pages.css alone', page => {
    const html = readFileSync(join(PUBLIC, `${page}.html`), 'utf8');
    expect(html).toContain('<link rel="stylesheet" href="/pages.css" />');
    expect(html).not.toMatch(/<style|style="|<font|<script/);
  });

  it("the figure page sets its text in the app's type", () => {
    const html = readFileSync(join(PUBLIC, 'figures/the-pass.html'), 'utf8');
    expect(html).toContain('href="/fonts/type.css"');
    expect(html).toContain('font-family:var(--portal-font)');
    expect(html).not.toMatch(/font(-family)?:[^;}]*ui-sans-serif/);
  });
});
