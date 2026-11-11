{%- macro wrap(open, inner, close) -%}
{%- if inner == '{children}' -%}
${{ open + inner + close }}
{%- else -%}
${{ open + '\n' + (inner | indent(2, true)) + '\n' + close }}
{%- endif -%}
{%- endmacro -%}
{%- set tree = '{children}' -%}
{%- if values.ui_framework == 'mui' -%}
{%- set tree = '<ThemeProvider theme={theme}>\n  <CssBaseline />\n  {children}\n</ThemeProvider>' -%}
{%- endif -%}
{%- if values.state_management == 'context' -%}
{%- set tree = wrap('<CounterProvider>', tree, '</CounterProvider>') -%}
{%- elif values.state_management == 'redux' -%}
{%- set tree = wrap('<StoreProvider store={store}>', tree, '</StoreProvider>') -%}
{%- endif -%}
{%- if values.api_client == 'react-query' -%}
{%- set tree = wrap('<QueryClientProvider client={queryClient}>', tree, '</QueryClientProvider>') -%}
{%- endif -%}
{%- set multiline = tree != '{children}' -%}
{%- set tree = wrap('<StrictMode>', tree, '</StrictMode>') -%}
{%- if values.ui_framework == 'mui' -%}
import { CssBaseline, ThemeProvider } from "@mui/material";
{% endif -%}
{%- if values.api_client == 'react-query' -%}
import { type QueryClient, QueryClientProvider } from "@tanstack/react-query";
{% endif -%}
{%- if values.state_management == 'redux' -%}
import { type ReactNode, StrictMode, useState } from "react";
import { Provider as StoreProvider } from "react-redux";
{%- else -%}
import { type ReactNode, StrictMode } from "react";
{%- endif %}
{%- if values.api_client == 'react-query' %}
import { createQueryClient } from "./api/queryClient";
{%- endif %}
{%- if values.state_management == 'context' %}
import { CounterProvider } from "./store/counter";
{%- elif values.state_management == 'redux' %}
import { createStore } from "./store/store";
{%- endif %}
{%- if values.ui_framework == 'mui' %}
import { theme } from "./theme";
{%- endif %}

interface AppProvidersProps {
  children: ReactNode;
{%- if values.api_client == 'react-query' %}
  /** Replaces the default query client, for example in tests. */
  queryClient?: QueryClient;
{%- endif %}
}
{%- if values.api_client == 'react-query' %}

const defaultQueryClient = createQueryClient();
{%- endif %}

/** Wraps the application in React strict mode and the providers its features need. */
{%- if values.api_client == 'react-query' %}
export function AppProviders({ children, queryClient = defaultQueryClient }: AppProvidersProps) {
{%- else %}
export function AppProviders({ children }: AppProvidersProps) {
{%- endif %}
{%- if values.state_management == 'redux' %}
  // One store per mounted tree keeps tests and stories independent of each other.
  const [store] = useState(createStore);
{%- endif %}
{%- if multiline %}
  return (
    ${{ tree | indent(4) }}
  );
{%- else %}
  return ${{ tree }};
{%- endif %}
}
