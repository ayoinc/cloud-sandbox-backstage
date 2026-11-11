import { describe, expect, it } from 'vitest';
import { TodoList } from './todos.svelte.ts';

describe('TodoList', () => {
	it('adds trimmed tasks and ignores blank ones', () => {
		const list = new TodoList();

		expect(list.add('  write tests  ')).toBe(true);
		expect(list.add('   ')).toBe(false);

		expect(list.items).toEqual([{ id: 1, text: 'write tests', done: false }]);
	});

	it('counts the tasks that remain', () => {
		const list = new TodoList();
		list.add('first');
		list.add('second');
		expect(list.remaining).toBe(2);

		list.toggle(1);
		expect(list.remaining).toBe(1);

		list.toggle(1);
		expect(list.remaining).toBe(2);
	});

	it('removes a task', () => {
		const list = new TodoList();
		list.add('first');
		list.add('second');

		list.remove(1);

		expect(list.items.map((todo) => todo.text)).toEqual(['second']);
	});
});
