/**
 * k6 Configuration
 *
 * Centralized configuration for all test scripts.
 */

export const config = {
  // Base URL for the target application
  baseUrl: __ENV.BASE_URL || '${{ values.baseUrl }}',

  // Virtual users at normal load
  vus: parseInt(__ENV.VUS, 10) || ${{ values.virtualUsers or 50 }},

  // Time spent at normal load
  duration: __ENV.DURATION || '${{ values.duration or "5m" }}',

  // Whether a run fails when a performance threshold is crossed
  thresholdsEnabled: __ENV.THRESHOLDS
    ? __ENV.THRESHOLDS !== 'false'
    : ${{ 'false' if values.thresholds === false else 'true' }},

  // API endpoints
  endpoints: {
    health: '/api/health',
    users: '/api/users',
    products: '/api/products',
  },

  // Request headers
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
};

/**
 * Returns the given thresholds, or none when thresholds are disabled.
 */
export function thresholds(limits) {
  return config.thresholdsEnabled ? limits : {};
}
