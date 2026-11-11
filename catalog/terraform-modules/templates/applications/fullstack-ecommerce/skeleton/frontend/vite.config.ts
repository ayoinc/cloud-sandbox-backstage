import react from '@vitejs/plugin-react';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  // Where the built assets are served from: set ASSET_BASE_URL to the address
  // of a CDN to load them from there.
  base: process.env.ASSET_BASE_URL ?? '/',
  plugins: [react()],
  server: {
    port: 3000,
    // In development the API runs next to the dev server.
    proxy: { '/api': process.env.API_URL ?? 'http://localhost:8080' },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test-setup.ts'],
  },
});
