import type { Preview } from "@storybook/react-vite";
import { AppProviders } from "../src/AppProviders";
{%- if values.ui_framework != 'mui' %}
import "../src/styles/index.css";
{%- endif %}

const preview: Preview = {
  // Stories render inside the same providers as the application.
  decorators: [
    (Story) => (
      <AppProviders>
        <Story />
      </AppProviders>
    ),
  ],
};

export default preview;
