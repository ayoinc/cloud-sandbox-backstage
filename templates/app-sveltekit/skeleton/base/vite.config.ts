import adapter from '@sveltejs/adapter-${{ values.adapter }}';
import { sveltekit } from '@sveltejs/kit/vite';
import { playwright } from '@vitest/browser-playwright';
import { defineConfig } from 'vitest/config';

export default defineConfig({
	plugins: [
		sveltekit({
			compilerOptions: {
				// Runes mode for the whole project, libraries excepted.
				runes: ({ filename }) =>
					filename.split(/[/\\]/).includes('node_modules') ? undefined : true
			},
{%- if values.adapter == 'static' %}
			// Hosts serve 404.html for paths that match no file.
			adapter: adapter({ fallback: '404.html' })
{%- else %}
			adapter: adapter()
{%- endif %}
		})
	],
	test: {
		expect: { requireAssertions: true },
		projects: [
			{
				// Component tests run in a real browser.
				extends: './vite.config.ts',
				test: {
					name: 'client',
					browser: {
						enabled: true,
						provider: playwright(),
						instances: [{ browser: 'chromium', headless: true }]
					},
					include: ['src/**/*.svelte.{test,spec}.{js,ts}'],
					exclude: ['src/lib/server/**']
				}
			},
			{
				// Everything else runs in Node.js.
				extends: './vite.config.ts',
				test: {
					name: 'server',
					environment: 'node',
					include: ['src/**/*.{test,spec}.{js,ts}'],
					exclude: ['src/**/*.svelte.{test,spec}.{js,ts}']
				}
			}
		]
	}
});
