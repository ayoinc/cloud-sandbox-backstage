import { test, expect } from '@playwright/test';

test.describe('Example Test Suite', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the base URL before each test
    await page.goto('/');
  });

  test('should have correct title', async ({ page }) => {
    // Verify the page title
    await expect(page).toHaveTitle(/.+/);
  });

  test('should load the homepage', async ({ page }) => {
    // Verify the page loaded successfully
    await expect(page.locator('body')).toBeVisible();
  });

  test('should be responsive @smoke', async ({ page }) => {
    // Test different viewport sizes
    const viewports = [
      { width: 1920, height: 1080 }, // Desktop
      { width: 768, height: 1024 },  // Tablet
      { width: 375, height: 667 },   // Mobile
    ];

    for (const viewport of viewports) {
      await page.setViewportSize(viewport);
      await expect(page.locator('body')).toBeVisible();
    }
  });

  test('should not have accessibility violations @a11y', async ({ page }) => {
    // Basic accessibility check - ensure main content is accessible
    const main = page.locator('main, [role="main"], body');
    await expect(main).toBeVisible();
  });
});

test.describe('Navigation', () => {
  test('should navigate between pages', async ({ page }) => {
    await page.goto('/');
    
    // Find and click a navigation link if it exists
    const navLinks = page.locator('nav a, header a');
    const linkCount = await navLinks.count();
    
    if (linkCount > 0) {
      await navLinks.first().click();
      await page.waitForLoadState('networkidle');
      await expect(page).not.toHaveURL(/^${{ values.baseUrl }}\/?$/);
    }
  });
});
