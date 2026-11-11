import { screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { App } from "../src/App";
import app from "../src/app.json";
import { defaultItems } from "./support/api";
import { renderWithProviders } from "./support/render";

describe("App", () => {
  it("shows the application name and the home page", async () => {
    renderWithProviders(<App />);

    expect(screen.getByRole("heading", { level: 1, name: app.name })).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 2, name: "Counter" })).toBeInTheDocument();
    expect(await screen.findByText(defaultItems[0].name)).toBeInTheDocument();
  });
});
