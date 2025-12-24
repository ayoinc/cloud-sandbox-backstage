import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
{%- if values.routing == 'react-router' %}
import { BrowserRouter } from "react-router-dom";
{%- endif %}
{%- if values.ui_framework == 'mui' %}
import { ThemeProvider, CssBaseline } from "@mui/material";
import { theme } from "./styles/theme";
{%- endif %}
{%- if values.api_client == 'react-query' %}
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      retry: 1,
    },
  },
});
{%- endif %}

import App from "./App";
import "./styles/index.css";

const rootElement = document.getElementById("root");
if (!rootElement) {
  throw new Error("Root element not found");
}

createRoot(rootElement).render(
  <StrictMode>
{%- if values.api_client == 'react-query' %}
    <QueryClientProvider client={queryClient}>
{%- endif %}
{%- if values.ui_framework == 'mui' %}
      <ThemeProvider theme={theme}>
        <CssBaseline />
{%- endif %}
{%- if values.routing == 'react-router' %}
        <BrowserRouter>
          <App />
        </BrowserRouter>
{%- else %}
        <App />
{%- endif %}
{%- if values.ui_framework == 'mui' %}
      </ThemeProvider>
{%- endif %}
{%- if values.api_client == 'react-query' %}
    </QueryClientProvider>
{%- endif %}
  </StrictMode>,
);
