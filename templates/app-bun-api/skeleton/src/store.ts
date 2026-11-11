export type Item = {
  id: string;
  name: string;
  createdAt: string;
};

/**
 * What the routes need from a repository. Implement it on a database to
 * replace the in-memory store.
 */
export interface ItemStore {
  list(): Promise<Item[]>;
  get(id: string): Promise<Item | undefined>;
  create(name: string): Promise<Item>;
}

/**
 * Keeps items in process memory: they are lost on restart and not shared
 * between replicas.
 */
export class MemoryItemStore implements ItemStore {
  readonly #items = new Map<string, Item>();

  async list(): Promise<Item[]> {
    return [...this.#items.values()];
  }

  async get(id: string): Promise<Item | undefined> {
    return this.#items.get(id);
  }

  async create(name: string): Promise<Item> {
    const item: Item = {
      id: Bun.randomUUIDv7(),
      name,
      createdAt: new Date().toISOString(),
    };
    this.#items.set(item.id, item);
    return item;
  }
}
