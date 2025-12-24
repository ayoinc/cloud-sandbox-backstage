import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
{%- if values.routing == 'react-router' %}
import { BrowserRouter } from 'react-router-dom';
{%- endif %}
import { Home } from '../src/pages/Home';

function renderHome() {
  return render(
{%- if values.routing == 'react-router' %}
    <BrowserRouter>
      <Home />
    </BrowserRouter>
{%- else %}
    <Home />
{%- endif %}
  );
}

describe('Home Page', () => {
  it('renders the home page', () => {
    renderHome();
    expect(screen.getByRole('heading', { level: 1 })).toBeInTheDocument();
  });

  it('displays welcome message', () => {
    renderHome();
    expect(screen.getByText(/welcome/i)).toBeInTheDocument();
  });

  it('has the correct heading', () => {
    renderHome();
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('${{ values.name }}');
  });
});
