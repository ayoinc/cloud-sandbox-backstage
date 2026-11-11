import sitemap from '@astrojs/sitemap';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'astro/config';
import site from './site.config.json' with { type: 'json' };

// https://docs.astro.build/en/reference/configuration-reference/
export default defineConfig({
  // Public origin of the site: canonical links, the sitemap and the feed.
  site: site.url,
  // Path the site is served under. Links are built with src/lib/paths.ts.
  base: site.basePath,
  trailingSlash: 'always',
  integrations: [sitemap()],
  vite: {
    plugins: [tailwindcss()],
  },
});
