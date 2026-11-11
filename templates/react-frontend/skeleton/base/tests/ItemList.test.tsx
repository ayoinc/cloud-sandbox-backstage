import { screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { ItemList } from "../src/components/ItemList";
import { defaultItems, respondWithItems, respondWithStatus } from "./support/api";
import { renderWithProviders } from "./support/render";

describe("ItemList", () => {
  it("shows the items returned by the API", async () => {
    renderWithProviders(<ItemList />);

    expect(screen.getByRole("status")).toHaveTextContent("Loading items...");
    for (const item of defaultItems) {
      expect(await screen.findByText(item.name)).toBeInTheDocument();
    }
    expect(screen.queryByRole("status")).not.toBeInTheDocument();
  });

  it("reports a failed request", async () => {
    respondWithStatus(500);
    renderWithProviders(<ItemList />);

    expect(await screen.findByRole("alert")).toHaveTextContent("Could not load items");
  });

  it("says so when there are no items", async () => {
    respondWithItems([]);
    renderWithProviders(<ItemList />);

    expect(await screen.findByText("No items yet.")).toBeInTheDocument();
  });
});
