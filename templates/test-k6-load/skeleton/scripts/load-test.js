/**
 * k6 Load Test Script
 * 
 * This script performs load testing against the target application.
 * Default configuration: ${{ values.virtualUsers }} VUs for ${{ values.duration }}
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { config } from './lib/config.js';

// Custom metrics
const errorRate = new Rate('error_rate');
const apiDuration = new Trend('api_duration');

// Test configuration
export const options = {
  stages: [
    { duration: '1m', target: Math.floor(${{ values.virtualUsers }} / 2) },  // Ramp up
    { duration: '${{ values.duration }}', target: ${{ values.virtualUsers }} },  // Stay at peak
    { duration: '1m', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1500'],
    http_req_failed: ['rate<0.01'],
    error_rate: ['rate<0.05'],
  },
};

// Setup function (runs once at the start)
export function setup() {
  console.log(`Starting load test against ${config.baseUrl}`);
  
  // Verify target is reachable
  const res = http.get(config.baseUrl);
  if (res.status !== 200) {
    throw new Error(`Target not reachable: ${res.status}`);
  }
  
  return { startTime: new Date().toISOString() };
}

// Main test function (runs repeatedly for each VU)
export default function(data) {
  // GET request to homepage
  const homeResponse = http.get(config.baseUrl);
  
  check(homeResponse, {
    'homepage status is 200': (r) => r.status === 200,
    'homepage response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  errorRate.add(homeResponse.status !== 200);
  apiDuration.add(homeResponse.timings.duration);

  // GET request to API endpoint (if exists)
  const apiResponse = http.get(`${config.baseUrl}/api/health`, {
    tags: { name: 'health_check' },
  });
  
  check(apiResponse, {
    'API health check returns 200': (r) => r.status === 200 || r.status === 404,
  });

  // Simulate user think time
  sleep(Math.random() * 3 + 1); // 1-4 seconds
}

// Teardown function (runs once at the end)
export function teardown(data) {
  console.log(`Load test completed. Started at: ${data.startTime}`);
}
