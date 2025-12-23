/*
 * Copyright 2023 The Backstage Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { defineConfig, devices } from '@playwright/test';

/**
 * Backstage E2E Test Configuration
 * 
 * Test Categories:
 * - Smoke Tests: Quick health checks (yarn test:e2e --grep "Smoke")
 * - Integration Tests: API integration (yarn test:e2e --grep "Integration")
 * - E2E Tests: User workflows (yarn test:e2e --grep "E2E")
 * - All Tests: Full suite (yarn test:e2e)
 * 
 * Environment Variables:
 * - PLAYWRIGHT_URL: Base URL for tests (default: http://localhost:7007)
 * - CI: Set in CI environments for stricter settings
 */
export default defineConfig({
  testDir: './packages/app/e2e-tests',
  timeout: 60_000,
  
  expect: {
    timeout: 10_000,
  },

  // Run tests in parallel
  fullyParallel: true,

  // Fail the build on CI if you accidentally left test.only in the source code
  forbidOnly: !!process.env.CI,

  // Retry on CI only
  retries: process.env.CI ? 2 : 0,

  // Limit parallel workers on CI
  workers: process.env.CI ? 2 : undefined,

  // Reporter configuration
  reporter: [
    ['list'],
    ['html', { 
      open: 'never', 
      outputFolder: 'e2e-test-report' 
    }],
    ['json', { 
      outputFile: 'e2e-test-results.json' 
    }],
  ],

  // Shared settings for all projects
  use: {
    // Base URL for the tests
    baseURL: process.env.PLAYWRIGHT_URL ?? 'http://localhost:7007',
    
    // Collect trace when retrying the failed test
    trace: 'on-first-retry',
    
    // Screenshot on failure
    screenshot: 'only-on-failure',
    
    // Video on failure (useful for debugging)
    video: 'on-first-retry',
    
    // Timeout for each action
    actionTimeout: 15_000,
    
    // Timeout for navigation
    navigationTimeout: 30_000,
  },

  // Output directory for test artifacts
  outputDir: 'node_modules/.cache/e2e-test-results',

  // Projects for different browsers/configurations
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    // Uncomment to test on other browsers
    // {
    //   name: 'firefox',
    //   use: { ...devices['Desktop Firefox'] },
    // },
    // {
    //   name: 'webkit',
    //   use: { ...devices['Desktop Safari'] },
    // },
    // {
    //   name: 'Mobile Chrome',
    //   use: { ...devices['Pixel 5'] },
    // },
  ],

  // Web server configuration (for local development)
  webServer: process.env.CI
    ? undefined // In CI, expect server to be running
    : {
        command: 'echo "Using existing server at PLAYWRIGHT_URL"',
        url: process.env.PLAYWRIGHT_URL ?? 'http://localhost:7007',
        reuseExistingServer: true,
        timeout: 120_000,
      },
});
