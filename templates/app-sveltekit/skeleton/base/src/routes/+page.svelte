<script lang="ts">
	import { TodoApp } from '#lib';
	import site from '#lib/site.json';
</script>

<svelte:head>
	<title>{site.name}</title>
</svelte:head>

<h1>{site.name}</h1>
<p class="lead">{site.description}</p>

<TodoApp heading="Getting started" />

<style>
	.lead {
		color: var(--muted);
		font-size: 1.125rem;
	}
</style>
