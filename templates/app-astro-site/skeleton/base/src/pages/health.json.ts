import { getPosts } from '../lib/posts';

// A small file for uptime checks: it shows that the site is being served and
// which build is live.
export async function GET() {
  const posts = await getPosts();
  return Response.json({
    status: 'ok',
    builtAt: new Date().toISOString(),
    commit: process.env['GITHUB_SHA'] ?? null,
    posts: posts.length,
  });
}
