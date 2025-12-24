{%- if values.enable_mock_api %}
import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

export const worker = setupWorker(...handlers);
{%- endif %}
