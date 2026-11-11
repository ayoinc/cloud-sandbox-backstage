import { describe, expect, it } from 'vitest';
import { page } from 'vitest/browser';
import { render } from 'vitest-browser-svelte';
import { TodoList } from '../todos.svelte.ts';
import TodoApp from './TodoApp.svelte';

describe('TodoApp.svelte', () => {
	it('adds a task and clears the field', async () => {
		render(TodoApp, { heading: 'Release checklist' });

		await expect
			.element(page.getByRole('heading', { level: 2 }))
			.toHaveTextContent('Release checklist');
		await expect.element(page.getByRole('status')).toHaveTextContent('Nothing to do yet.');

		const field = page.getByLabelText('New task');
		await field.fill('Tag the release');
		await page.getByRole('button', { name: 'Add' }).click();

		await expect.element(page.getByText('Tag the release')).toBeInTheDocument();
		await expect.element(field).toHaveValue('');
		await expect.element(page.getByRole('status')).toHaveTextContent('1 of 1 left');
	});

	it('reflects changes made to the list it was given', async () => {
		const list = new TodoList();
		list.add('Write the changelog');
		render(TodoApp, { list });

		await page.getByRole('checkbox').click();
		await expect.element(page.getByRole('status')).toHaveTextContent('0 of 1 left');
		expect(list.items[0]?.done).toBe(true);

		await page.getByRole('button', { name: 'Remove Write the changelog' }).click();
		await expect.element(page.getByRole('status')).toHaveTextContent('Nothing to do yet.');
	});
});
