import { randomUUID } from 'node:crypto';

export interface Note {
  id: string;
  title: string;
  body: string;
  tags: string[];
  createdAt: string;
}

export class NoteLimitError extends Error {}

/**
 * Notes kept in memory: the sample domain behind the tools and resources.
 * Replace it with the system your server gives AI clients access to.
 */
export class NoteStore {
  readonly #notes = new Map<string, Note>();
  readonly #limit: number;

  constructor(limit = 1000) {
    this.#limit = limit;
  }

  add(input: { title: string; body: string; tags?: string[] }): Note {
    if (this.#notes.size >= this.#limit) {
      throw new NoteLimitError(`The store holds at most ${String(this.#limit)} notes.`);
    }
    const note: Note = {
      id: randomUUID(),
      title: input.title,
      body: input.body,
      tags: [...new Set((input.tags ?? []).map(tag => tag.toLowerCase()))],
      createdAt: new Date().toISOString(),
    };
    this.#notes.set(note.id, note);
    return note;
  }

  get(id: string): Note | undefined {
    return this.#notes.get(id);
  }

  list(): Note[] {
    return [...this.#notes.values()];
  }

  /** Notes whose title, body or tags contain the query, optionally with a tag. */
  search(query: string, tag?: string): Note[] {
    const needle = query.trim().toLowerCase();
    const wanted = tag?.toLowerCase();
    return this.list().filter(note => {
      if (wanted && !note.tags.includes(wanted)) {
        return false;
      }
      return (
        needle === '' ||
        note.title.toLowerCase().includes(needle) ||
        note.body.toLowerCase().includes(needle) ||
        note.tags.some(candidate => candidate.includes(needle))
      );
    });
  }

  delete(id: string): boolean {
    return this.#notes.delete(id);
  }
}
