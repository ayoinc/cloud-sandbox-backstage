import type { FC } from "react";
{%- if values.routing == 'react-router' %}
import { Routes, Route } from "react-router-dom";
import { Home } from "./pages/Home";
import { About } from "./pages/About";
import { NotFound } from "./pages/NotFound";
{%- endif %}

const App: FC = () => {
{%- if values.routing == 'react-router' %}
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/about" element={<About />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  );
{%- else %}
  return (
    <main>
      <h1>${{ values.name }}</h1>
      <p>${{ values.description }}</p>
    </main>
  );
{%- endif %}
};

export default App;
