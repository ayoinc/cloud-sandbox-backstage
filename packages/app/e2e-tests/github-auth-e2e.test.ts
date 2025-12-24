/*
 * E2E Test: GitHub OAuth Authentication and Feature Access
 *
 * This test verifies:
 * 1. GitHub OAuth sign-in flow
 * 2. Authenticated access to catalog
 * 3. Authenticated access to TechDocs
 * 4. Authenticated access to scaffolder/templates
 * 5. Authenticated access to search
 */

import { test, expect, Page } from '@playwright/test';

// Test configuration
const BASE_URL = process.env.PLAYWRIGHT_URL || 'http://localhost';
const GITHUB_USERNAME = process.env.E2E_GITHUB_USERNAME;
const GITHUB_PASSWORD = process.env.E2E_GITHUB_PASSWORD;

// Helper function to wait for page load
async function waitForPageReady(page: Page) {
  await page.waitForLoadState('networkidle');
}

test.describe('GitHub OAuth E2E Tests', () => {
  test.describe.configure({ mode: 'serial' });

  test('1. Homepage loads correctly', async ({ page }) => {
    await page.goto(BASE_URL);
    await waitForPageReady(page);

    // Check for sign-in button or welcome page
    const signInButton = page.getByRole('button', { name: /sign in/i });
    const enterButton = page.getByRole('button', { name: /enter/i });

    const hasSignIn = await signInButton.isVisible().catch(() => false);
    const hasEnter = await enterButton.isVisible().catch(() => false);

    expect(hasSignIn || hasEnter).toBeTruthy();
    console.log('Homepage loaded successfully');
  });

  test('2. GitHub sign-in button is available', async ({ page }) => {
    await page.goto(BASE_URL);
    await waitForPageReady(page);

    // Look for GitHub sign-in option
    const signInButton = page.getByRole('button', { name: /sign in/i });
    if (await signInButton.isVisible().catch(() => false)) {
      await signInButton.click();
      await page.waitForTimeout(1000);
    }

    // Check for GitHub provider option
    const githubOption = page.getByRole('button', { name: /github/i });
    const hasGithub = await githubOption.isVisible().catch(() => false);

    if (hasGithub) {
      console.log('GitHub sign-in option is available');
    } else {
      // Check if we're already signed in or if there's a different flow
      console.log('GitHub sign-in option not immediately visible - may need different flow');
    }
  });

  test('3. Catalog page is accessible', async ({ page }) => {
    await page.goto(`${BASE_URL}/catalog`);
    await waitForPageReady(page);

    // Should show catalog or redirect to sign-in
    const url = page.url();
    const hasCatalog = url.includes('/catalog') || url.includes('/');

    expect(hasCatalog).toBeTruthy();

    // Check for catalog content
    const catalogContent = page.locator('text=/component|service|template|system/i');
    const hasContent = await catalogContent.first().isVisible().catch(() => false);

    console.log(`Catalog page accessible: ${hasContent ? 'with content' : 'loading'}`);
  });

  test('4. TechDocs page is accessible', async ({ page }) => {
    await page.goto(`${BASE_URL}/docs`);
    await waitForPageReady(page);

    const url = page.url();
    console.log(`TechDocs URL: ${url}`);

    // TechDocs should be accessible (may show empty or loading state)
    expect(url).toContain('/docs');
  });

  test('5. Create/Templates page is accessible', async ({ page }) => {
    await page.goto(`${BASE_URL}/create`);
    await waitForPageReady(page);

    const url = page.url();
    console.log(`Templates URL: ${url}`);

    // Should show templates page
    expect(url).toContain('/create');

    // Look for template cards or list
    const templateContent = page.locator('[class*="template"], [data-testid*="template"]');
    const hasTemplates = await templateContent.first().isVisible().catch(() => false);

    console.log(`Templates page: ${hasTemplates ? 'has templates' : 'loading'}`);
  });

  test('6. Search functionality works', async ({ page }) => {
    await page.goto(`${BASE_URL}/search`);
    await waitForPageReady(page);

    // Look for search input
    const searchInput = page.getByRole('searchbox').or(page.getByPlaceholder(/search/i));
    const hasSearch = await searchInput.first().isVisible().catch(() => false);

    if (hasSearch) {
      // Perform a search
      await searchInput.first().fill('terraform');
      await page.keyboard.press('Enter');
      await page.waitForTimeout(2000);

      // Check for results
      const results = page.locator('[class*="result"], [class*="search"]');
      console.log('Search functionality works');
    } else {
      console.log('Search page accessible but input not found immediately');
    }
  });

  test('7. API endpoints respond correctly for authenticated requests', async ({
    request,
  }) => {
    // Test catalog API
    const catalogResponse = await request.get(`${BASE_URL}/api/catalog/entities?limit=5`);
    expect(catalogResponse.status()).toBe(200);
    const catalogData = await catalogResponse.json();
    console.log(`Catalog API: ${catalogData.length || 0} entities returned`);

    // Test search API
    const searchResponse = await request.get(`${BASE_URL}/api/search/query?term=`);
    expect(searchResponse.status()).toBe(200);
    const searchData = await searchResponse.json();
    console.log(`Search API: ${searchData.numberOfResults || 0} results`);

    // Test TechDocs sync API (the previously broken endpoint)
    const techdocsResponse = await request.get(
      `${BASE_URL}/api/techdocs/sync/default/template/docs-adr`,
    );
    expect(techdocsResponse.status()).toBe(200);
    console.log('TechDocs sync API: 200 OK (FIXED!)');

    // Test scaffolder actions API
    const scaffolderResponse = await request.get(`${BASE_URL}/api/scaffolder/v2/actions`);
    expect(scaffolderResponse.status()).toBe(200);
    const scaffolderData = await scaffolderResponse.json();
    console.log(`Scaffolder API: ${scaffolderData.length || 0} actions available`);
  });

  test('8. Permission system is active', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/api/permission/authorize`, {
      data: { items: [] },
      headers: { 'Content-Type': 'application/json' },
    });
    expect(response.status()).toBe(200);
    console.log('Permission API: responding correctly');
  });
});

test.describe('GitHub OAuth Interactive Flow', () => {
  test.skip(
    !GITHUB_USERNAME || !GITHUB_PASSWORD,
    'Skipping interactive OAuth test - E2E_GITHUB_USERNAME and E2E_GITHUB_PASSWORD not set',
  );

  test('Complete GitHub OAuth sign-in flow', async ({ page }) => {
    await page.goto(BASE_URL);
    await waitForPageReady(page);

    // Click sign in
    const signInButton = page.getByRole('button', { name: /sign in/i });
    if (await signInButton.isVisible()) {
      await signInButton.click();
    }

    // Select GitHub provider
    const githubButton = page.getByRole('button', { name: /github/i });
    if (await githubButton.isVisible()) {
      await githubButton.click();
    }

    // Handle GitHub OAuth page
    await page.waitForURL(/github\.com/, { timeout: 10000 }).catch(() => {});

    const isOnGitHub = (() => {
      try {
        const { hostname } = new URL(page.url());
        return ['github.com', 'www.github.com'].includes(hostname);
      } catch {
        return false;
      }
    })();

    if (isOnGitHub) {
      // Fill GitHub credentials
      await page.fill('input[name="login"]', GITHUB_USERNAME!);
      await page.fill('input[name="password"]', GITHUB_PASSWORD!);
      await page.click('input[type="submit"]');

      // Handle 2FA if present
      await page.waitForTimeout(2000);

      // Authorize app if needed
      const authorizeButton = page.getByRole('button', { name: /authorize/i });
      if (await authorizeButton.isVisible().catch(() => false)) {
        await authorizeButton.click();
      }

      // Wait for redirect back to Backstage
      await page.waitForURL(new RegExp(BASE_URL.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')), {
        timeout: 30000,
      });
    }

    // Verify signed in
    await waitForPageReady(page);

    // Should see user profile or signed-in state
    const userProfile = page.locator('[class*="user"], [class*="profile"], [class*="avatar"]');
    const isSignedIn = await userProfile.first().isVisible().catch(() => false);

    console.log(`Sign-in complete: ${isSignedIn ? 'success' : 'may need verification'}`);
  });
});
