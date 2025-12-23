/**
 * k6 Soak Test Script
 * 
 * This script tests system stability over an extended period to find
 * memory leaks, resource exhaustion, and other long-term issues.
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter } from 'k6/metrics';
import { config } from './lib/config.js';

const errorRate = new Rate('error_rate');
const requestCounter = new Counter('total_requests');

export const options = {
  stages: [
    { duration: '5m', target: 100 },    // Ramp up
    { duration: '4h', target: 100 },    // Stay at load for 4 hours
    { duration: '5m', target: 0 },      // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1500'],
    http_req_failed: ['rate<0.01'],
    error_rate: ['rate<0.01'],
  },
};

export function setup() {
  console.log(`Starting soak test against ${config.baseUrl}`);
  console.log('This test will run for approximately 4 hours');
  return { startTime: new Date().toISOString() };
}

export default function() {
  const response = http.get(config.baseUrl);
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  errorRate.add(response.status !== 200);
  requestCounter.add(1);
  
  // Normal think time
  sleep(Math.random() * 3 + 1);
}

export function teardown(data) {
  const endTime = new Date().toISOString();
  console.log(`Soak test completed.`);
  console.log(`Started: ${data.startTime}`);
  console.log(`Ended: ${endTime}`);
}
