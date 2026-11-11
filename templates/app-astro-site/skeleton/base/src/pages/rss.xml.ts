import rss from '@astrojs/rss';
import type { APIContext } from 'astro';
import { href } from '../lib/paths';
import { getPosts } from '../lib/posts';
import { SITE } from '../site';

export async function GET(context: APIContext) {
  const posts = await getPosts();
  return rss({
    title: SITE.title,
    description: SITE.description,
    site: new URL(href(''), context.site ?? context.url),
    items: posts.map((post) => ({
      title: post.data.title,
      description: post.data.description,
      pubDate: post.data.pubDate,
      link: href(`posts/${post.id}/`),
    })),
  });
}
