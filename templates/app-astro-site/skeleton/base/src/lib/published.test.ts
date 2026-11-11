import { describe, expect, it } from 'vitest';
import { formatDate, published } from './published';

const entry = (id: string, pubDate: string, draft = false) => ({
  id,
  data: { pubDate: new Date(pubDate), draft },
});

describe('published', () => {
  const entries = [
    entry('old', '2026-01-10'),
    entry('draft', '2026-03-01', true),
    entry('new', '2026-02-20'),
  ];

  it('sorts newest first and leaves drafts out', () => {
    expect(published(entries, false).map((e) => e.id)).toEqual(['new', 'old']);
  });

  it('includes drafts on request', () => {
    expect(published(entries, true).map((e) => e.id)).toEqual([
      'draft',
      'new',
      'old',
    ]);
  });

  it('does not reorder its input', () => {
    published(entries, true);
    expect(entries.map((e) => e.id)).toEqual(['old', 'draft', 'new']);
  });
});

describe('formatDate', () => {
  it('formats in UTC, whatever the time zone of the build', () => {
    expect(formatDate(new Date('2026-02-20T23:30:00Z'))).toBe(
      '20 February 2026',
    );
  });
});
