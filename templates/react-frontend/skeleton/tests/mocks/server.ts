{%- if values.enable_mock_api %}
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
{%- endif %}
