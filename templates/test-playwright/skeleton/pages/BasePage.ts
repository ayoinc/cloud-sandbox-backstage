import { Page, Locator, expect } from '@playwright/test';

/**
 * Base Page Object class that all page objects should extend.
 * Provides common functionality and utilities for page interactions.
 */
export class BasePage {
  protected page: Page;

  constructor(page: Page) {
    this.page = page;
  }

  /**
   * Navigate to a specific path
   */
  async navigate(path: string = '/') {
    await this.page.goto(path);
    await this.waitForPageLoad();
  }

  /**
   * Wait for the page to fully load
   */
  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  /**
   * Get the current page URL
   */
  async getCurrentUrl(): Promise<string> {
    return this.page.url();
  }

  /**
   * Get the page title
   */
  async getTitle(): Promise<string> {
    return this.page.title();
  }

  /**
   * Take a screenshot with a custom name
   */
  async takeScreenshot(name: string) {
    await this.page.screenshot({ path: `screenshots/${name}.png`, fullPage: true });
  }

  /**
   * Wait for an element to be visible
   */
  async waitForElement(selector: string, timeout: number = 30000) {
    await this.page.locator(selector).waitFor({ state: 'visible', timeout });
  }

  /**
   * Click an element with retry logic
   */
  async clickWithRetry(locator: Locator, retries: number = 3) {
    for (let i = 0; i < retries; i++) {
      try {
        await locator.click();
        return;
      } catch (error) {
        if (i === retries - 1) throw error;
        await this.page.waitForTimeout(1000);
      }
    }
  }

  /**
   * Fill a form field and verify the value
   */
  async fillAndVerify(locator: Locator, value: string) {
    await locator.fill(value);
    await expect(locator).toHaveValue(value);
  }

  /**
   * Scroll to an element
   */
  async scrollToElement(locator: Locator) {
    await locator.scrollIntoViewIfNeeded();
  }

  /**
   * Check if an element exists on the page
   */
  async elementExists(selector: string): Promise<boolean> {
    return (await this.page.locator(selector).count()) > 0;
  }

  /**
   * Get all text content from matching elements
   */
  async getAllTextContent(selector: string): Promise<string[]> {
    return this.page.locator(selector).allTextContents();
  }

  /**
   * Wait for network to be idle
   */
  async waitForNetworkIdle() {
    await this.page.waitForLoadState('networkidle');
  }

  /**
   * Handle common dialogs
   */
  async acceptDialog() {
    this.page.on('dialog', dialog => dialog.accept());
  }

  async dismissDialog() {
    this.page.on('dialog', dialog => dialog.dismiss());
  }
}
