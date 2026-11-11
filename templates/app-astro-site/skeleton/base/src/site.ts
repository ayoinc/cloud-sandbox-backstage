import config from '../site.config.json' with { type: 'json' };

/** Texts shared by every page; edit them in site.config.json. */
export const SITE = {
  title: config.title,
  description: config.description,
  language: 'en',
} as const;

export const NAVIGATION = [
  { label: 'Home', path: '' },
  { label: 'Posts', path: 'posts/' },
] as const;
