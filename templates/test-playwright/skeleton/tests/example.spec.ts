import { test, expect } from './fixtures/base';

test.describe('Example Test Suite', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the base URL before each test
    await page.goto('/');
  });

  test('should have correct title', async ({ basePage }) => {
    // Verify the page has a non-empty title
    expect(await basePage.getTitle()).not.toBe('');
  });

  test('should load the homepage', async ({ page }) => {
    // Verify the page loaded successfully
    await expect(page.locator('body')).toBeVisible();
  });

  test('should be responsive @smoke', async ({ page }) => {
    // Test different viewport sizes
    const viewports = [
      { width: 1920, height: 1080 }, // Desktop
      { width: 768, height: 1024 }, // Tablet
      { width: 375, height: 667 }, // Mobile
    ];

    for (const viewport of viewports) {
      await page.setViewportSize(viewport);
      await expect(page.locator('body')).toBeVisible();
    }
  });

  test('should expose its main content @a11y', async ({ page }) => {
    // Basic accessibility check - the page has visible content to land on
    const main = page.locator('main, [role="main"], body').first();
    await expect(main).toBeVisible();
  });
});

test.describe('Navigation', () => {
  test('should navigate between pages', async ({ page }) => {
    await page.goto('/');
    const startUrl = page.url();

    // Follow the first visible same-site navigation link, if the page has one
    const navLink = page
      .locator('nav a[href^="/"]:visible, header a[href^="/"]:visible')
      .first();

    if ((await navLink.count()) > 0) {
      const href = await navLink.getAttribute('href');
      test.skip(href === '/', 'the first navigation link points at the start page');
      await navLink.click();
      await expect(page).not.toHaveURL(startUrl);
    }
  });
});
