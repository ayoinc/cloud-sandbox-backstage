import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";
{%- if values.state_management == 'zustand' %}
import { useCounter } from "../src/store/counter";
{%- endif %}
import { installApiDouble } from "./support/api";

installApiDouble();

afterEach(() => {
  cleanup();
{%- if values.state_management == 'zustand' %}
  // The Zustand store is a module-level singleton: start every test from its initial state.
  useCounter.setState(useCounter.getInitialState(), true);
{%- endif %}
});
