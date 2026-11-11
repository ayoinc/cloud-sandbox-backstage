/** Joins the base path of the site and a path inside it. */
export function withBase(base: string, path: string): string {
  const root = base.endsWith('/') ? base : `${base}/`;
  return root + path.replace(/^\/+/, '');
}

/**
 * The URL of a page or file of this site. Use it for every internal link so
 * that the site keeps working when it is served under a sub-path.
 */
export const href = (path: string): string =>
  withBase(import.meta.env.BASE_URL, path);
