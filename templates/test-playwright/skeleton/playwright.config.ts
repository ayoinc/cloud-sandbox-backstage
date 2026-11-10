{%- set browsers = values.browsers if values.browsers and values.browsers.length else ['chromium'] -%}
import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for ${{ values.name }}
 * @see https://playwright.dev/docs/test-configuration
 */

/* USE_DEMO_APP=1 starts the bundled demo app and runs the tests against it. */
const useDemoApp = process.env.USE_DEMO_APP === '1';
const demoAppPort = Number(process.env.DEMO_APP_PORT || 3100);
const baseURL = useDemoApp
  ? `http://127.0.0.1:${demoAppPort}`
  : process.env.BASE_URL || '${{ values.baseUrl }}';

export default defineConfig({
  testDir: './tests',

  /* Run tests in files in parallel */
  fullyParallel: true,

  /* Fail the build on CI if you accidentally left test.only in the source code */
  forbidOnly: !!process.env.CI,

  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,

  /* Parallel workers */
  workers: process.env.CI ? 2 : ${{ values.parallelWorkers or 4 }},

  /* Reporter to use */
  reporter: process.env.CI
    ? [['html', { outputFolder: 'playwright-report', open: 'never' }], ['list'], ['github']]
    : [['html', { outputFolder: 'playwright-report' }], ['list']],

  /* Shared settings for all the projects below */
  use: {
    /* Base URL to use in actions like `await page.goto('/')` */
    baseURL,

    /* Collect trace when retrying the failed test */
    trace: '${{ "on-first-retry" if values.enableTracing else "off" }}',

    /* Capture screenshot on failure */
    screenshot: '${{ "only-on-failure" if values.enableScreenshots else "off" }}',

    /* Video recording */
    video: 'retain-on-failure',
  },

  /* Configure projects for the selected browsers */
  projects: [
{%- if 'chromium' in browsers %}
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
{%- endif %}
{%- if 'firefox' in browsers %}
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
{%- endif %}
{%- if 'webkit' in browsers %}
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
{%- endif %}
    /* Test against mobile viewports */
{%- if 'chromium' in browsers %}
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
{%- endif %}
{%- if 'webkit' in browsers %}
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
{%- endif %}
  ],

  /* Start the bundled demo app when the tests target it */
  webServer: useDemoApp
    ? {
        command: 'node demo-app/server.js',
        url: baseURL,
        env: { PORT: String(demoAppPort) },
        reuseExistingServer: !process.env.CI,
      }
    : undefined,
});
