/**
 * k6 Soak Test Script
 * 
 * This script tests system stability over an extended period to find
 * memory leaks, resource exhaustion, and other long-term issues.
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Counter } from 'k6/metrics';
import { config, thresholds } from './lib/config.js';

const errorRate = new Rate('error_rate');
const requestCounter = new Counter('total_requests');

// Time spent at load (override with -e SOAK_DURATION=<time>)
const soakDuration = __ENV.SOAK_DURATION || '4h';

export const options = {
  stages: [
    { duration: '5m', target: config.vus },            // Ramp up
    { duration: soakDuration, target: config.vus },    // Stay at load
    { duration: '5m', target: 0 },      // Ramp down
  ],
  thresholds: thresholds({
    http_req_duration: ['p(95)<500', 'p(99)<1500'],
    http_req_failed: ['rate<0.01'],
    error_rate: ['rate<0.01'],
  }),
};

export function setup() {
  console.log(`Starting soak test against ${config.baseUrl}`);
  console.log(`This test stays at load for ${soakDuration}`);
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
