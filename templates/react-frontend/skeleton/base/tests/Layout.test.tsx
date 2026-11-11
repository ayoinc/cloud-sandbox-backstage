import { screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { Layout } from "../src/components/Layout";
import { Section } from "../src/components/Section";
import { renderWithProviders } from "./support/render";

describe("Layout", () => {
  it("shows the title, the navigation and the page content", () => {
    renderWithProviders(
      <Layout title="Orders" nav={<a href="/about">About</a>}>
        <p>Page content</p>
      </Layout>,
    );

    expect(screen.getByRole("heading", { level: 1, name: "Orders" })).toBeInTheDocument();
    expect(
      within(screen.getByRole("navigation")).getByRole("link", { name: "About" }),
    ).toBeInTheDocument();
    expect(within(screen.getByRole("main")).getByText("Page content")).toBeInTheDocument();
  });

  it("has no navigation landmark when there are no links", () => {
    renderWithProviders(
      <Layout title="Orders">
        <p>Page content</p>
      </Layout>,
    );

    expect(screen.queryByRole("navigation")).not.toBeInTheDocument();
  });
});

describe("Section", () => {
  it("puts its content under a second-level heading", () => {
    renderWithProviders(
      <Section title="Details">
        <p>Section content</p>
      </Section>,
    );

    expect(screen.getByRole("heading", { level: 2, name: "Details" })).toBeInTheDocument();
    expect(screen.getByText("Section content")).toBeInTheDocument();
  });
});
