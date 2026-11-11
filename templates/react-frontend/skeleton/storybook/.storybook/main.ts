import type { StorybookConfig } from "@storybook/react-vite";
{%- if values.enable_pwa %}
import type { PluginOption } from "vite";

/** Tells whether the entry is one of the plugins that VitePWA() adds in vite.config.ts. */
function isPwaPlugin(plugin: PluginOption): boolean {
  return (
    typeof plugin === "object" &&
    plugin !== null &&
    "name" in plugin &&
    typeof plugin.name === "string" &&
    plugin.name.startsWith("vite-plugin-pwa")
  );
}
{%- endif %}

const config: StorybookConfig = {
  stories: ["../src/**/*.stories.tsx"],
  framework: "@storybook/react-vite",
  core: {
    disableTelemetry: true,
  },
{%- if values.enable_pwa %}
  // Storybook builds with vite.config.ts. The service worker and manifest of
  // the application do not belong in the static Storybook.
  viteFinal: (viteConfig) => ({
    ...viteConfig,
    plugins: viteConfig.plugins?.flat().filter((plugin) => !isPwaPlugin(plugin)),
  }),
{%- endif %}
};

export default config;
