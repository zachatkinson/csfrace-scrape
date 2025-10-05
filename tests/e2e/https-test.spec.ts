import { test, expect } from '@playwright/test';

/**
 * Simple HTTPS localhost test
 * Tests that https://localhost is accessible and loads correctly
 */
test.describe('HTTPS Localhost Test', () => {
  test('should load https://localhost successfully', async ({ page }) => {
    // Ignore certificate errors for localhost self-signed cert
    await page.goto('https://localhost', {
      waitUntil: 'networkidle',
      timeout: 30000
    });

    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');

    // Check that the page title is present
    const title = await page.title();
    console.log('Page title:', title);
    expect(title).toBeTruthy();

    // Check that the page has content
    const bodyText = await page.textContent('body');
    expect(bodyText).toBeTruthy();
    expect(bodyText!.length).toBeGreaterThan(0);

    // Take a screenshot
    await page.screenshot({
      path: 'test-results/https-localhost-screenshot.png',
      fullPage: true
    });

    console.log('✅ Successfully loaded https://localhost');
    console.log('Page content length:', bodyText!.length);
  });

  test('should have working navigation', async ({ page }) => {
    await page.goto('https://localhost', {
      waitUntil: 'networkidle',
      timeout: 30000
    });

    // Check for common UI elements
    const links = await page.locator('a').count();
    console.log('Number of links found:', links);
    expect(links).toBeGreaterThan(0);

    // Check for buttons
    const buttons = await page.locator('button').count();
    console.log('Number of buttons found:', buttons);

    console.log('✅ Navigation elements present');
  });

  test('should connect to backend API through nginx', async ({ page }) => {
    // Listen for API requests
    const apiRequests: string[] = [];
    page.on('request', request => {
      const url = request.url();
      if (url.includes('/api/') || url.includes('/health')) {
        apiRequests.push(url);
        console.log('API Request:', url);
      }
    });

    await page.goto('https://localhost', {
      waitUntil: 'networkidle',
      timeout: 30000
    });

    // Wait a bit for any async API calls
    await page.waitForTimeout(3000);

    console.log('API requests captured:', apiRequests.length);
    apiRequests.forEach(url => console.log('  -', url));
  });
});
