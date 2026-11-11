import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { Counter } from "../src/components/Counter";
import { renderWithProviders } from "./support/render";

describe("Counter", () => {
  it("starts at zero", () => {
    renderWithProviders(<Counter />);

    expect(screen.getByText("Count: 0")).toBeInTheDocument();
  });

  it("increases, decreases and resets the count", async () => {
    const user = userEvent.setup();
    renderWithProviders(<Counter />);

    await user.click(screen.getByRole("button", { name: "Increase" }));
    await user.click(screen.getByRole("button", { name: "Increase" }));
    expect(screen.getByText("Count: 2")).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Decrease" }));
    expect(screen.getByText("Count: 1")).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Reset" }));
    expect(screen.getByText("Count: 0")).toBeInTheDocument();
  });
});
