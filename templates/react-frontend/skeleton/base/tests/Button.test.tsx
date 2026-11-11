import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { Button } from "../src/components/Button";
import { renderWithProviders } from "./support/render";

describe("Button", () => {
  it("renders its label and reports clicks", async () => {
    const onClick = vi.fn();
    renderWithProviders(<Button onClick={onClick}>Save</Button>);

    await userEvent.click(screen.getByRole("button", { name: "Save" }));

    expect(onClick).toHaveBeenCalledTimes(1);
  });

  it("can be disabled", () => {
    renderWithProviders(<Button disabled>Save</Button>);

    expect(screen.getByRole("button", { name: "Save" })).toBeDisabled();
  });

  it("does not submit a form unless asked to", () => {
    renderWithProviders(
      <>
        <Button>Cancel</Button>
        <Button type="submit">Send</Button>
      </>,
    );

    expect(screen.getByRole("button", { name: "Cancel" })).toHaveAttribute("type", "button");
    expect(screen.getByRole("button", { name: "Send" })).toHaveAttribute("type", "submit");
  });
});
