import { createRoot } from "react-dom/client";
{%- if values.routing == 'react-router' %}
import { BrowserRouter } from "react-router-dom";
{%- endif %}
import { App } from "./App";
import { AppProviders } from "./AppProviders";
{%- if values.enable_monitoring %}
import { reportWebVitals } from "./monitoring/webVitals";
{%- endif %}
{%- if values.ui_framework != 'mui' %}
import "./styles/index.css";
{%- endif %}

const container = document.getElementById("root");
if (!container) {
  throw new Error("index.html has no element with the id root");
}
{%- if values.enable_mock_api %}

// The Mock Service Worker answers API requests in the browser. It is loaded
// only by the development server and only when VITE_ENABLE_MOCK_API is true.
if (import.meta.env.DEV && import.meta.env.VITE_ENABLE_MOCK_API === "true") {
  const { worker } = await import("./mocks/browser");
  await worker.start({ onUnhandledFrame: "bypass" });
}
{%- endif %}

createRoot(container).render(
  <AppProviders>
{%- if values.routing == 'react-router' %}
    <BrowserRouter>
      <App />
    </BrowserRouter>
{%- else %}
    <App />
{%- endif %}
  </AppProviders>,
);
{%- if values.enable_monitoring %}

reportWebVitals();
{%- endif %}
