/**
 * Helper functions for k6 tests
 */

import { check } from 'k6';
import http from 'k6/http';
import { config } from './config.js';

/**
 * Generate random string
 */
export function randomString(length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Generate random email
 */
export function randomEmail() {
  return `user_${randomString(8)}@example.com`;
}

/**
 * Make authenticated request
 */
export function authRequest(method, url, body, token) {
  const headers = {
    ...config.headers,
    'Authorization': `Bearer ${token}`,
  };
  
  const params = { headers };
  
  switch (method.toUpperCase()) {
    case 'GET':
      return http.get(url, params);
    case 'POST':
      return http.post(url, JSON.stringify(body), params);
    case 'PUT':
      return http.put(url, JSON.stringify(body), params);
    case 'DELETE':
      return http.del(url, null, params);
    default:
      throw new Error(`Unsupported method: ${method}`);
  }
}

/**
 * Check response and log errors
 */
export function checkResponse(response, checks) {
  const result = check(response, checks);
  
  if (!result) {
    console.error(`Request failed: ${response.status} - ${response.body}`);
  }
  
  return result;
}

/**
 * Parse JSON response safely
 */
export function parseJSON(response) {
  try {
    return JSON.parse(response.body);
  } catch (e) {
    console.error(`Failed to parse JSON: ${e.message}`);
    return null;
  }
}
