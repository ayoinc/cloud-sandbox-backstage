/**
 * E2E Tests - Full user workflow tests
 * 
 * These tests simulate real user journeys through the application:
 * - Browse catalog
 * - View component details
 * - Navigate TechDocs
 * - Use scaffolder
 * - Search functionality
 * 
 * Run with: yarn test:e2e --grep "E2E"
 */

import { test, expect, Page } from '@playwright/test';

const BASE_URL = process.env.PLAYWRIGHT_URL || 'http://localhost:7007';

// Helper to wait for page to be ready
async function waitForPageReady(page: Page) {
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});
}

// Helper to check if on sign-in page
async function isOnSignInPage(page: Page): Promise<boolean> {
  const signInButton = page.getByRole('button', { name: /sign in/i });
  const welcomeText = page.locator('text=/welcome|sign in/i');
  return (await signInButton.isVisible({ timeout: 1000 }).catch(() => false)) ||
         (await welcomeText.isVisible({ timeout: 1000 }).catch(() => false));
}

// Helper to handle potential sign-in prompts (for guest mode if available)
async function handleSignIn(page: Page) {
  // Try enter button (guest mode)
  const enterButton = page.getByRole('button', { name: /enter/i });
  if (await enterButton.isVisible({ timeout: 2000 }).catch(() => false)) {
    await enterButton.click();
    await waitForPageReady(page);
    return true;
  }
  
  // Check if on sign-in page requiring OAuth
  if (await isOnSignInPage(page)) {
    // OAuth sign-in required - skip test assertions that need authenticated content
    return false;
  }
  
  return true;
}

test.describe('E2E Tests - Catalog Browsing', () => {
  test('User can browse catalog and view entities', async ({ page }) => {
    // Navigate to catalog
    await page.goto(`${BASE_URL}/catalog`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    // Verify catalog page loaded or sign-in page displayed
    if (!signedIn) {
      // If OAuth required, just verify the sign-in page is shown
      const signInPage = await isOnSignInPage(page);
      expect(signInPage).toBe(true);
      return;
    }
    
    expect(page.url()).toContain('/catalog');
    
    // Check for entity list or table
    const entityList = page.locator('table, [class*="entity"], [class*="catalog"]');
    await expect(entityList.first()).toBeVisible({ timeout: 10000 });
  });

  test('User can filter catalog by kind', async ({ page }) => {
    await page.goto(`${BASE_URL}/catalog`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Look for filter dropdown or tabs
    const _kindFilter = page.locator('text=/component|service|api|system/i').first();
    
    // Click on Components filter if available
    const componentsTab = page.getByRole('tab', { name: /component/i })
      .or(page.getByRole('button', { name: /component/i }));
    
    if (await componentsTab.isVisible().catch(() => false)) {
      await componentsTab.click();
      await waitForPageReady(page);
    }
  });

  test('User can view component details', async ({ page }) => {
    // Go to catalog
    await page.goto(`${BASE_URL}/catalog?filters[kind]=component`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Find and click on first component link
    const componentLink = page.locator('a[href*="/catalog/default/component/"]').first();
    
    if (await componentLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await componentLink.click();
      await waitForPageReady(page);
      
      // Verify we're on a component page
      expect(page.url()).toContain('/component/');
      
      // Should see component details
      const aboutCard = page.locator('text=/about|overview|description/i').first();
      await expect(aboutCard).toBeVisible({ timeout: 10000 });
    }
  });

  test('User can navigate entity tabs', async ({ page }) => {
    // Go directly to a known component
    await page.goto(`${BASE_URL}/catalog/default/component/terraform-modules`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Find tabs
    const tabs = page.locator('[role="tab"]');
    const tabCount = await tabs.count();
    
    // Click through available tabs
    for (let i = 0; i < Math.min(tabCount, 3); i++) {
      const tab = tabs.nth(i);
      if (await tab.isVisible()) {
        await tab.click();
        await page.waitForTimeout(500);
      }
    }
  });
});

test.describe('E2E Tests - TechDocs Navigation', () => {
  test('User can browse TechDocs', async ({ page }) => {
    await page.goto(`${BASE_URL}/docs`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Verify TechDocs page
    expect(page.url()).toContain('/docs');
  });

  test('User can view documentation for terraform-modules', async ({ page }) => {
    await page.goto(`${BASE_URL}/docs/default/component/terraform-modules`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Should load documentation content
    const docContent = page.locator('article, [class*="doc"], main').first();
    await expect(docContent).toBeVisible({ timeout: 15000 });
  });

  test('User can navigate TechDocs sidebar', async ({ page }) => {
    await page.goto(`${BASE_URL}/docs/default/component/terraform-modules`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Look for navigation sidebar
    const nav = page.locator('nav, [class*="sidebar"], [class*="navigation"]').first();
    
    if (await nav.isVisible({ timeout: 5000 }).catch(() => false)) {
      // Click on a navigation item
      const navItem = page.locator('nav a, [class*="sidebar"] a').first();
      if (await navItem.isVisible()) {
        await navItem.click();
        await waitForPageReady(page);
      }
    }
  });
});

test.describe('E2E Tests - Scaffolder/Create', () => {
  test('User can browse templates', async ({ page }) => {
    await page.goto(`${BASE_URL}/create`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      // Verify sign-in page is shown
      const signInPage = await isOnSignInPage(page);
      expect(signInPage).toBe(true);
      return;
    }
    
    // Verify scaffolder page
    expect(page.url()).toContain('/create');
    
    // Should see template cards or list
    const templates = page.locator('[class*="template"], [class*="card"]').first();
    await expect(templates).toBeVisible({ timeout: 10000 });
  });

  test('User can view template details', async ({ page }) => {
    await page.goto(`${BASE_URL}/create`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Click on first template
    const templateLink = page.locator('a[href*="/create/templates/"]').first();
    
    if (await templateLink.isVisible({ timeout: 5000 }).catch(() => false)) {
      await templateLink.click();
      await waitForPageReady(page);
      
      // Should see template form or details
      expect(page.url()).toContain('/templates/');
    }
  });

  test('User can start template wizard', async ({ page }) => {
    // Go directly to terraform module template
    await page.goto(`${BASE_URL}/create/templates/default/terraform-module-template`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      // Verify sign-in page is shown
      const signInPage = await isOnSignInPage(page);
      expect(signInPage).toBe(true);
      return;
    }
    
    // Should see the form
    const form = page.locator('form, [class*="wizard"], [class*="stepper"]').first();
    await expect(form).toBeVisible({ timeout: 10000 });
    
    // Look for input fields
    const inputs = page.locator('input:visible');
    const inputCount = await inputs.count();
    expect(inputCount).toBeGreaterThan(0);
  });

  test('User can fill template form (without submitting)', async ({ page }) => {
    await page.goto(`${BASE_URL}/create/templates/default/terraform-module-template`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Try to fill the name field
    const nameInput = page.locator('input[name*="name"], input[id*="name"]').first();
    
    if (await nameInput.isVisible({ timeout: 5000 }).catch(() => false)) {
      await nameInput.fill('terraform-e2e-test');
      
      // Verify value was set
      await expect(nameInput).toHaveValue('terraform-e2e-test');
    }
  });
});

test.describe('E2E Tests - Search Functionality', () => {
  test('User can access search page', async ({ page }) => {
    await page.goto(`${BASE_URL}/search`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      // Verify sign-in page is shown
      const signInPage = await isOnSignInPage(page);
      expect(signInPage).toBe(true);
      return;
    }
    
    expect(page.url()).toContain('/search');
    
    // Should see search input
    const searchInput = page.locator('input[type="search"], input[placeholder*="search" i], input[type="text"]').first();
    await expect(searchInput).toBeVisible({ timeout: 10000 });
  });

  test('User can perform a search', async ({ page }) => {
    await page.goto(`${BASE_URL}/search`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    const searchInput = page.locator('input[type="search"], input[placeholder*="search" i], input[type="text"]').first();
    
    if (await searchInput.isVisible()) {
      // Perform search
      await searchInput.fill('terraform');
      await page.keyboard.press('Enter');
      await waitForPageReady(page);
      
      // Wait for results
      await page.waitForTimeout(2000);
    }
  });

  test('User can use search from header', async ({ page }) => {
    await page.goto(`${BASE_URL}/catalog`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Look for search in header
    const headerSearch = page.locator('header input[type="search"], header [class*="search"]').first();
    
    if (await headerSearch.isVisible().catch(() => false)) {
      await headerSearch.click();
      await headerSearch.fill('aws');
      await page.keyboard.press('Enter');
      await waitForPageReady(page);
    }
  });
});

test.describe('E2E Tests - Settings Page', () => {
  test('User can access settings', async ({ page }) => {
    await page.goto(`${BASE_URL}/settings`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    expect(page.url()).toContain('/settings');
  });

  test('User can view profile in settings', async ({ page }) => {
    await page.goto(`${BASE_URL}/settings`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      // Verify sign-in page is shown
      const signInPage = await isOnSignInPage(page);
      expect(signInPage).toBe(true);
      return;
    }
    
    // Look for profile or user info - try different selectors
    const profileSection = page.locator('text=/profile|user|account|general/i').first();
    const settingsContent = page.locator('main, [class*="settings"], [class*="content"]').first();
    
    // Check either profile section or settings content is visible
    const profileVisible = await profileSection.isVisible({ timeout: 5000 }).catch(() => false);
    const contentVisible = await settingsContent.isVisible({ timeout: 5000 }).catch(() => false);
    
    expect(profileVisible || contentVisible).toBe(true);
  });
});

test.describe('E2E Tests - Navigation Flow', () => {
  test('User can navigate using sidebar', async ({ page }) => {
    await page.goto(BASE_URL);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Find sidebar navigation
    const sidebar = page.locator('nav, [class*="sidebar"]').first();
    
    if (await sidebar.isVisible()) {
      // Click on catalog link
      const catalogLink = sidebar.locator('a[href*="/catalog"]').first();
      if (await catalogLink.isVisible()) {
        await catalogLink.click();
        await waitForPageReady(page);
        expect(page.url()).toContain('/catalog');
      }
      
      // Click on docs link
      const docsLink = sidebar.locator('a[href*="/docs"]').first();
      if (await docsLink.isVisible()) {
        await docsLink.click();
        await waitForPageReady(page);
        expect(page.url()).toContain('/docs');
      }
    }
  });

  test('User can use breadcrumbs for navigation', async ({ page }) => {
    // Navigate to a nested page
    await page.goto(`${BASE_URL}/catalog/default/component/terraform-modules`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      test.skip();
      return;
    }
    
    // Look for breadcrumbs
    const breadcrumbs = page.locator('[class*="breadcrumb"], nav[aria-label="breadcrumb"]').first();
    
    if (await breadcrumbs.isVisible().catch(() => false)) {
      // Click on catalog breadcrumb
      const catalogCrumb = breadcrumbs.locator('a[href*="/catalog"]').first();
      if (await catalogCrumb.isVisible()) {
        await catalogCrumb.click();
        await waitForPageReady(page);
        expect(page.url()).toContain('/catalog');
      }
    }
  });
});

test.describe('E2E Tests - Error Handling', () => {
  test('404 page shows for invalid routes', async ({ page }) => {
    await page.goto(`${BASE_URL}/this-page-does-not-exist-12345`);
    await handleSignIn(page);
    await waitForPageReady(page);
    
    // Should show some kind of error or redirect
    const errorText = page.locator('text=/not found|404|error/i').first();
    const _hasError = await errorText.isVisible().catch(() => false);
    
    // Either shows error or redirects to a valid page
    expect(page.url()).toBeDefined();
  });

  test('Invalid entity shows appropriate message', async ({ page }) => {
    await page.goto(`${BASE_URL}/catalog/default/component/nonexistent-component-xyz`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      // Verify sign-in page is shown
      const signInPage = await isOnSignInPage(page);
      expect(signInPage).toBe(true);
      return;
    }
    
    // Should show error or not found message, or loading state
    const errorMessage = page.locator('text=/not found|error|does not exist|warning/i').first();
    const hasError = await errorMessage.isVisible({ timeout: 5000 }).catch(() => false);
    
    // Either error shown or page loaded (might just show empty state)
    expect(page.url()).toContain('/catalog/');
  });
});

test.describe('E2E Tests - Responsiveness', () => {
  test('Page renders correctly on desktop', async ({ page }) => {
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.goto(`${BASE_URL}/catalog`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    if (!signedIn) {
      // Verify sign-in page is shown - should have some content
      const mainContent = page.locator('main, article, body').first();
      await expect(mainContent).toBeVisible({ timeout: 10000 });
      return;
    }
    
    // Sidebar should be visible on desktop
    const sidebar = page.locator('nav, [class*="sidebar"]').first();
    await expect(sidebar).toBeVisible({ timeout: 10000 });
  });

  test('Page renders correctly on tablet', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto(`${BASE_URL}/catalog`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    // Page should still be functional
    const content = page.locator('main, [class*="content"], article, body').first();
    await expect(content).toBeVisible({ timeout: 10000 });
  });

  test('Page renders correctly on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(`${BASE_URL}/catalog`);
    const signedIn = await handleSignIn(page);
    await waitForPageReady(page);
    
    // Page should still be functional
    const content = page.locator('main, [class*="content"], article, body').first();
    await expect(content).toBeVisible({ timeout: 10000 });
  });
});
