/**
 * k6 Stress Test Script
 * 
 * This script finds the system's breaking point by gradually increasing load.
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';
import { config } from './lib/config.js';

const errorRate = new Rate('error_rate');

export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Below normal load
    { duration: '5m', target: 100 },   // Stay at normal
    { duration: '2m', target: 200 },   // Normal load
    { duration: '5m', target: 200 },   // Stay at normal
    { duration: '2m', target: 300 },   // Around breaking point
    { duration: '5m', target: 300 },   // Stay at breaking point
    { duration: '2m', target: 400 },   // Beyond breaking point
    { duration: '5m', target: 400 },   // Stay beyond breaking point
    { duration: '5m', target: 0 },     // Recovery stage
  ],
  thresholds: {
    http_req_duration: ['p(99)<3000'],  // More lenient for stress test
    error_rate: ['rate<0.50'],          // Allow higher error rate to find breaking point
  },
};

export function setup() {
  console.log(`Starting stress test against ${config.baseUrl}`);
  return { startTime: new Date().toISOString() };
}

export default function() {
  const response = http.get(config.baseUrl);
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time acceptable': (r) => r.timings.duration < 3000,
  });
  
  errorRate.add(response.status !== 200);
  
  sleep(1);
}

export function teardown(data) {
  console.log(`Stress test completed. Started at: ${data.startTime}`);
}
