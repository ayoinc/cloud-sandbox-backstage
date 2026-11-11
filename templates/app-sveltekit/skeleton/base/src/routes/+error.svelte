<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
</script>

<svelte:head>
	<title>{page.status} {page.error?.message}</title>
</svelte:head>

<h1>{page.status}</h1>
<p>{page.error?.message}</p>
<a href={resolve('/')}>Back to the home page</a>
