import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it } from "vitest";
import { App } from "../src/App";
import app from "../src/app.json";
import { defaultItems } from "./support/api";
import { renderWithProviders } from "./support/render";

function renderAt(path: string) {
  return renderWithProviders(
    <MemoryRouter initialEntries={[path]}>
      <App />
    </MemoryRouter>,
  );
}

describe("App", () => {
  it("shows the application name and the home page at /", async () => {
    renderAt("/");

    expect(screen.getByRole("heading", { level: 1, name: app.name })).toBeInTheDocument();
    expect(screen.getByRole("heading", { level: 2, name: "Counter" })).toBeInTheDocument();
    expect(await screen.findByText(defaultItems[0].name)).toBeInTheDocument();
  });

  it("navigates to the about page and marks its link as current", async () => {
    renderAt("/");

    await userEvent.click(screen.getByRole("link", { name: "About" }));

    expect(screen.getByRole("heading", { level: 2, name: "About" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "About" })).toHaveAttribute("aria-current", "page");
  });

  it("shows the not found page for an unknown address", () => {
    renderAt("/missing");

    expect(screen.getByRole("heading", { level: 2, name: "Page not found" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Back to the home page" })).toHaveAttribute(
      "href",
      "/",
    );
  });
});
