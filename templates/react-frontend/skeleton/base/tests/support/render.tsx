{%- if values.api_client == 'react-query' -%}
import { QueryClient } from "@tanstack/react-query";
{% endif -%}
import { render } from "@testing-library/react";
import type { ReactElement } from "react";
import { AppProviders } from "../../src/AppProviders";

/** Renders `ui` inside the same providers as the application. */
export function renderWithProviders(ui: ReactElement) {
{%- if values.api_client == 'react-query' %}
  // A client per test starts with an empty cache; without retries a failed request is reported at once.
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(<AppProviders queryClient={queryClient}>{ui}</AppProviders>);
{%- else %}
  return render(<AppProviders>{ui}</AppProviders>);
{%- endif %}
}
