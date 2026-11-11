import type { APIContext } from 'astro';
import { href } from '../lib/paths';

export function GET(context: APIContext) {
  const sitemap = new URL(
    href('sitemap-index.xml'),
    context.site ?? context.url,
  );
  return new Response(`User-agent: *\nAllow: /\n\nSitemap: ${sitemap}\n`, {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  });
}
