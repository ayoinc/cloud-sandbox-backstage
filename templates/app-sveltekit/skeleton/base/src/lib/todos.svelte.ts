export type Todo = {
	id: number;
	text: string;
	done: boolean;
};

/**
 * A list of tasks whose state is reactive: components that read `items` or
 * `remaining` update when they change. Runes work in `.svelte.ts` modules as
 * they do in components.
 */
export class TodoList {
	items = $state<Todo[]>([]);
	remaining = $derived(this.items.filter((todo) => !todo.done).length);
	#nextId = 1;

	/** Adds a task. Returns false when the text is blank. */
	add(text: string): boolean {
		const trimmed = text.trim();
		if (trimmed === '') {
			return false;
		}
		this.items.push({ id: this.#nextId++, text: trimmed, done: false });
		return true;
	}

	toggle(id: number): void {
		const todo = this.items.find((item) => item.id === id);
		if (todo) {
			todo.done = !todo.done;
		}
	}

	remove(id: number): void {
		this.items = this.items.filter((item) => item.id !== id);
	}
}
