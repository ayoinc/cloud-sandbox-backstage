import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
{%- if values.routing == 'react-router' %}
import { BrowserRouter } from 'react-router-dom';
{%- endif %}
{%- if values.api_client == 'react-query' %}
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
{%- endif %}
import App from '../src/App';

{%- if values.api_client == 'react-query' %}
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
});
{%- endif %}

function renderApp() {
  return render(
{%- if values.api_client == 'react-query' %}
    <QueryClientProvider client={queryClient}>
{%- endif %}
{%- if values.routing == 'react-router' %}
      <BrowserRouter>
        <App />
      </BrowserRouter>
{%- else %}
      <App />
{%- endif %}
{%- if values.api_client == 'react-query' %}
    </QueryClientProvider>
{%- endif %}
  );
}

describe('App', () => {
  it('renders without crashing', () => {
    renderApp();
    expect(document.body).toBeInTheDocument();
  });

  it('renders the application name', () => {
    renderApp();
    // Update this to match your actual heading/title
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });

  it('has accessible navigation', () => {
    renderApp();
    const nav = document.querySelector('nav');
    expect(nav).toBeInTheDocument();
  });
});
