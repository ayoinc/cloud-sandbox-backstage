/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL?: string;
{%- if values.enable_mock_api %}
  readonly VITE_ENABLE_MOCK_API?: string;
{%- endif %}
{%- if values.enable_monitoring %}
  readonly VITE_VITALS_ENDPOINT?: string;
{%- endif %}
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
