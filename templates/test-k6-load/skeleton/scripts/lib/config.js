/**
 * k6 Configuration
 * 
 * Centralized configuration for all test scripts.
 */

export const config = {
  // Base URL for the target application
  baseUrl: __ENV.BASE_URL || '${{ values.baseUrl }}',
  
  // Default virtual users
  defaultVUs: parseInt(__ENV.VUS) || ${{ values.virtualUsers }},
  
  // Default test duration
  defaultDuration: __ENV.DURATION || '${{ values.duration }}',
  
  // API endpoints
  endpoints: {
    health: '/api/health',
    users: '/api/users',
    products: '/api/products',
  },
  
  // Request headers
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  
  // Thresholds
  thresholds: {
    responseTime: {
      p95: 500,
      p99: 1500,
    },
    errorRate: 0.01,
  },
};
