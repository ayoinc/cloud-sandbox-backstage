type Dated = { data: { pubDate: Date; draft: boolean } };

/**
 * The entries to show, newest first. Drafts are left out unless
 * `includeDrafts` is set, which the site does in development.
 */
export function published<T extends Dated>(
  entries: readonly T[],
  includeDrafts: boolean,
): T[] {
  return entries
    .filter((entry) => includeDrafts || !entry.data.draft)
    .sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
}

const dateFormat = new Intl.DateTimeFormat('en-GB', {
  day: 'numeric',
  month: 'long',
  year: 'numeric',
  timeZone: 'UTC',
});

export const formatDate = (date: Date): string => dateFormat.format(date);
