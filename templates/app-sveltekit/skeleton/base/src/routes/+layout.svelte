<script lang="ts">
	import '../app.css';
	import { resolve } from '$app/paths';
	import site from '#lib/site.json';
	import type { LayoutProps } from './$types';

	let { children }: LayoutProps = $props();
</script>

<svelte:head>
	<meta name="description" content={site.description} />
</svelte:head>

<header>
	<a href={resolve('/')}>{site.name}</a>
</header>

<main>
	{@render children()}
</main>

<style>
	header,
	main {
		max-width: 44rem;
		margin: 0 auto;
		padding: 1rem;
	}

	header {
		border-bottom: 1px solid var(--border);
	}

	header a {
		color: inherit;
		font-weight: 600;
		text-decoration: none;
	}
</style>
