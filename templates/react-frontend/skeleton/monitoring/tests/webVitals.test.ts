import { afterEach, describe, expect, it, vi } from "vitest";
import type { Metric } from "web-vitals";
import { beaconReporter, consoleReporter, reportWebVitals } from "../src/monitoring/webVitals";

const { listeners } = vi.hoisted(() => ({
  listeners: new Map<string, (metric: Metric) => void>(),
}));

// The real library only reports inside a browser that paints; the test
// captures the callbacks it would call instead.
vi.mock("web-vitals", () => ({
  onCLS: (callback: (metric: Metric) => void) => listeners.set("CLS", callback),
  onFCP: (callback: (metric: Metric) => void) => listeners.set("FCP", callback),
  onINP: (callback: (metric: Metric) => void) => listeners.set("INP", callback),
  onLCP: (callback: (metric: Metric) => void) => listeners.set("LCP", callback),
  onTTFB: (callback: (metric: Metric) => void) => listeners.set("TTFB", callback),
}));

const lcp = { name: "LCP", value: 1200, rating: "good", id: "v1-123" } as Metric;

afterEach(() => {
  listeners.clear();
  vi.restoreAllMocks();
});

describe("reportWebVitals", () => {
  it("subscribes the reporter to every metric", () => {
    const report = vi.fn();

    reportWebVitals(report);
    listeners.get("LCP")?.(lcp);

    expect([...listeners.keys()].sort()).toEqual(["CLS", "FCP", "INP", "LCP", "TTFB"]);
    expect(report).toHaveBeenCalledWith(lcp);
  });

  it("writes to the console when no endpoint is configured", () => {
    const info = vi.spyOn(console, "info").mockImplementation(() => {});

    reportWebVitals();
    listeners.get("LCP")?.(lcp);

    expect(info).toHaveBeenCalledWith("[web-vitals] LCP: 1200 (good)");
  });
});

describe("consoleReporter", () => {
  it("prints the name, value and rating", () => {
    const info = vi.spyOn(console, "info").mockImplementation(() => {});

    consoleReporter(lcp);

    expect(info).toHaveBeenCalledWith("[web-vitals] LCP: 1200 (good)");
  });
});

describe("beaconReporter", () => {
  it("posts the measurement as JSON to the endpoint", async () => {
    const sendBeacon = vi.fn((_url: string, _data: Blob) => true);
    Object.defineProperty(navigator, "sendBeacon", { value: sendBeacon, configurable: true });

    beaconReporter("https://vitals.example.com/collect")(lcp);

    expect(sendBeacon).toHaveBeenCalledTimes(1);
    const [url, data] = sendBeacon.mock.calls[0];
    expect(url).toBe("https://vitals.example.com/collect");
    expect(JSON.parse(await data.text())).toEqual({
      name: "LCP",
      value: 1200,
      rating: "good",
      id: "v1-123",
      page: "/",
    });
  });
});
