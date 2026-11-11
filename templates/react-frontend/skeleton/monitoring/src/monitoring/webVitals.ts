import { type Metric, onCLS, onFCP, onINP, onLCP, onTTFB } from "web-vitals";

/** Receives one Web Vitals measurement. */
export type VitalsReporter = (metric: Metric) => void;

/** Writes the measurement to the browser console. */
export const consoleReporter: VitalsReporter = (metric) => {
  console.info(`[web-vitals] ${metric.name}: ${metric.value} (${metric.rating})`);
};

/**
 * Creates a reporter that posts the measurement as JSON to `endpoint` with
 * `navigator.sendBeacon`, which still delivers it while the page is unloading.
 */
export function beaconReporter(endpoint: string): VitalsReporter {
  return (metric) => {
    const body = JSON.stringify({
      name: metric.name,
      value: metric.value,
      rating: metric.rating,
      id: metric.id,
      page: window.location.pathname,
    });
    navigator.sendBeacon(endpoint, new Blob([body], { type: "application/json" }));
  };
}

/**
 * Measures the Core Web Vitals (CLS, INP, LCP) plus FCP and TTFB of the page
 * and hands each result to `report`. By default results go to the URL in
 * `VITE_VITALS_ENDPOINT`, or to the console when that variable is empty.
 */
export function reportWebVitals(report?: VitalsReporter): void {
  const endpoint = import.meta.env.VITE_VITALS_ENDPOINT;
  const reporter = report ?? (endpoint ? beaconReporter(endpoint) : consoleReporter);

  onCLS(reporter);
  onFCP(reporter);
  onINP(reporter);
  onLCP(reporter);
  onTTFB(reporter);
}
