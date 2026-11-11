<script lang="ts">
	import { TodoList } from '../todos.svelte.ts';

	type Props = {
		heading?: string;
		list?: TodoList;
	};

	let { heading = 'Tasks', list = new TodoList() }: Props = $props();

	let draft = $state('');
	const summary = $derived(
		list.items.length === 0
			? 'Nothing to do yet.'
			: `${list.remaining} of ${list.items.length} left`
	);

	function submit(event: SubmitEvent) {
		event.preventDefault();
		if (list.add(draft)) {
			draft = '';
		}
	}
</script>

<section aria-labelledby="todo-heading">
	<h2 id="todo-heading">{heading}</h2>

	<form onsubmit={submit}>
		<label for="todo-input">New task</label>
		<div class="row">
			<input id="todo-input" bind:value={draft} autocomplete="off" />
			<button type="submit">Add</button>
		</div>
	</form>

	<ul>
		{#each list.items as todo (todo.id)}
			<li>
				<label class:done={todo.done}>
					<input type="checkbox" checked={todo.done} onchange={() => list.toggle(todo.id)} />
					{todo.text}
				</label>
				<button
					type="button"
					aria-label={`Remove ${todo.text}`}
					onclick={() => list.remove(todo.id)}
				>
					Remove
				</button>
			</li>
		{/each}
	</ul>

	<p role="status">{summary}</p>
</section>

<style>
	section {
		border: 1px solid var(--border);
		border-radius: 0.75rem;
		padding: 1.5rem;
	}

	h2 {
		margin-top: 0;
	}

	.row {
		display: flex;
		gap: 0.5rem;
		margin-top: 0.25rem;
	}

	input:not([type='checkbox']) {
		flex: 1;
		padding: 0.5rem 0.75rem;
		border: 1px solid var(--border);
		border-radius: 0.5rem;
		font: inherit;
	}

	button {
		padding: 0.5rem 0.75rem;
		border: 1px solid var(--border);
		border-radius: 0.5rem;
		background: white;
		font: inherit;
		cursor: pointer;
	}

	button[type='submit'] {
		border-color: var(--brand);
		background: var(--brand);
		color: white;
	}

	ul {
		padding: 0;
		list-style: none;
	}

	li {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1rem;
		padding: 0.5rem 0;
		border-bottom: 1px solid var(--border);
	}

	.done {
		color: var(--muted);
		text-decoration: line-through;
	}

	[role='status'] {
		margin-bottom: 0;
		color: var(--muted);
	}
</style>
