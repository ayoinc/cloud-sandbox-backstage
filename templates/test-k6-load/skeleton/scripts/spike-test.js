/**
 * k6 Spike Test Script
 * 
 * This script tests system behavior under sudden, extreme load increases.
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { config } from './lib/config.js';

const errorRate = new Rate('error_rate');

export const options = {
  stages: [
    { duration: '10s', target: 100 },   // Ramp up to normal load
    { duration: '1m', target: 100 },    // Stay at normal
    { duration: '10s', target: 1400 },  // SPIKE to 14x normal!
    { duration: '3m', target: 1400 },   // Stay at spike load
    { duration: '10s', target: 100 },   // Scale back to normal
    { duration: '3m', target: 100 },    // Recovery period
    { duration: '10s', target: 0 },     // Ramp down to 0
  ],
  thresholds: {
    http_req_duration: ['p(99)<5000'],  // Very lenient during spike
    http_req_failed: ['rate<0.30'],     // Allow some failures during spike
  },
};

export function setup() {
  console.log(`Starting spike test against ${config.baseUrl}`);
  return { startTime: new Date().toISOString() };
}

export default function() {
  const response = http.get(config.baseUrl);
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response received': (r) => r.body !== null,
  });
  
  errorRate.add(response.status !== 200);
  
  // Minimal think time during spike
  sleep(0.5);
}

export function teardown(data) {
  console.log(`Spike test completed. Started at: ${data.startTime}`);
}
