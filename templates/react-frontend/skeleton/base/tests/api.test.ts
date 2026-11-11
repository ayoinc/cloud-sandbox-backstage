import { describe, expect, it } from "vitest";
import { listItems } from "../src/api/client";
import { defaultItems, respondWithStatus } from "./support/api";

describe("listItems", () => {
  it("returns the items of GET /items", async () => {
    await expect(listItems()).resolves.toEqual(defaultItems);
  });

  it("rejects with the status of a failed response", async () => {
    respondWithStatus(503);

    await expect(listItems()).rejects.toMatchObject({ name: "ApiError", status: 503 });
  });
});
