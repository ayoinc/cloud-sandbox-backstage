import { type CollectionEntry, getCollection } from 'astro:content';
import { published } from './published';

export type Post = CollectionEntry<'posts'>;

/** Published posts, newest first. Drafts appear in development only. */
export async function getPosts(): Promise<Post[]> {
  return published(await getCollection('posts'), import.meta.env.DEV);
}
