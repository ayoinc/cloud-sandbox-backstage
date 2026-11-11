import { describe, expect, it } from 'vitest';
import { withBase } from './paths';

describe('withBase', () => {
  it('keeps root-relative paths at the root', () => {
    expect(withBase('/', 'posts/')).toBe('/posts/');
    expect(withBase('/', '')).toBe('/');
  });

  it('prefixes the base path', () => {
    expect(withBase('/handbook/', 'posts/')).toBe('/handbook/posts/');
    expect(withBase('/handbook', 'posts/')).toBe('/handbook/posts/');
  });

  it('ignores leading slashes of the path', () => {
    expect(withBase('/handbook/', '/rss.xml')).toBe('/handbook/rss.xml');
  });
});
