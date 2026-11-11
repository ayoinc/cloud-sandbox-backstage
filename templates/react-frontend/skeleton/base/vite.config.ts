{%- if values.ui_framework == 'tailwind' -%}
import tailwindcss from "@tailwindcss/vite";
{% endif -%}
import react from "@vitejs/plugin-react";
{%- if values.enable_mock_api %}
import { msw } from "msw/vite";
{%- endif %}
{%- if values.enable_pwa %}
import { VitePWA } from "vite-plugin-pwa";
{%- endif %}
import { defineConfig } from "vitest/config";
{%- if values.enable_pwa %}
import app from "./src/app.json" with { type: "json" };
{%- endif %}

export default defineConfig({
{%- if values.enable_pwa %}
  plugins: [
    react(),
{%- if values.ui_framework == 'tailwind' %}
    tailwindcss(),
{%- endif %}
{%- if values.enable_mock_api %}
    // Serves /mockServiceWorker.js from the development server only.
    { ...msw({ mode: "worker-only" }), apply: "serve" },
{%- endif %}
    // Generates dist/manifest.webmanifest and a service worker (dist/sw.js)
    // that precaches the build output and updates itself on new deployments.
    VitePWA({
      registerType: "autoUpdate",
      includeAssets: ["favicon.svg"],
      manifest: {
        name: app.name,
        short_name: app.name,
        description: app.description,
        theme_color: "#1565c0",
        background_color: "#ffffff",
        display: "standalone",
        icons: [
          { src: "pwa-192x192.png", sizes: "192x192", type: "image/png" },
          { src: "pwa-512x512.png", sizes: "512x512", type: "image/png" },
        ],
      },
    }),
  ],
{%- else %}
{%- if values.enable_mock_api %}
  // msw serves /mockServiceWorker.js from the development server only.
{%- endif %}
  plugins: [react()
{%- if values.ui_framework == 'tailwind' %}, tailwindcss(){% endif %}
{%- if values.enable_mock_api %}, { ...msw({ mode: "worker-only" }), apply: "serve" }{% endif %}],
{%- endif %}
  server: {
    port: 5173,
  },
  test: {
    environment: "jsdom",
    setupFiles: ["./tests/setup.ts"],
    include: ["tests/**/*.test.{ts,tsx}"],
    coverage: {
      provider: "v8",
      include: ["src/**/*.{ts,tsx}"],
      exclude: ["src/main.tsx", "src/mocks/browser.ts", "src/**/*.stories.tsx", "src/**/*.d.ts"],
      reporter: ["text", "lcov"],
    },
  },
});
