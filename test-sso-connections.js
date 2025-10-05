#!/usr/bin/env node

/**
 * Test SSO Connection Status Detection
 */

import { chromium } from 'playwright';

const BASE_URL = 'https://localhost';

console.log('🔗 Testing SSO Connection Status Detection...');

try {
  const browser = await chromium.launch({
    headless: false,
    ignoreHTTPSErrors: true,
  });

  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
  });

  const page = await context.newPage();

  // Monitor console logs for debugging
  page.on('console', msg => {
    if (msg.type() === 'log' && (msg.text().includes('OAuth') || msg.text().includes('SSO') || msg.text().includes('User data'))) {
      console.log(`🖥️  ${msg.text()}`);
    }
  });

  // Monitor errors
  page.on('pageerror', err => {
    console.log(`❌ JavaScript error: ${err.message}`);
  });

  console.log('🌐 Step 1: Navigate to main page...');
  await page.goto(BASE_URL, {
    waitUntil: 'networkidle',
    timeout: 30000
  });

  console.log('✅ Page loaded successfully');

  // Step 2: Simulate OAuth login success
  console.log('\n🔐 Step 2: Simulate OAuth authentication...');
  await page.evaluate(() => {
    // Simulate OAuth tokens being set
    localStorage.setItem('auth_token', 'test-token-12345');
    localStorage.setItem('auth_user', JSON.stringify({
      id: 'test-user',
      email: 'test@gmail.com',  // Google email to test domain matching
      name: 'Test User'
    }));

    // Dispatch auth-success event
    console.log('🔐 Dispatching auth-success event...');
    window.dispatchEvent(new CustomEvent('auth-success', {
      detail: {
        user: {
          id: 'test-user',
          email: 'test@gmail.com',
          name: 'Test User'
        }
      }
    }));
  });

  await page.waitForTimeout(2000);

  // Step 3: Open user settings modal
  console.log('\n⚙️  Step 3: Testing User Settings Modal...');
  const userSettingsButton = page.locator('#user-settings-button, [data-testid="user-settings"], button[class*="user-settings"]');

  if (await userSettingsButton.isVisible()) {
    await userSettingsButton.click();
    await page.waitForTimeout(2000);

    // Check SSO provider status
    console.log('\n📋 Step 4: Checking SSO provider connection status...');

    const providers = ['google', 'microsoft', 'github', 'facebook', 'apple'];

    for (const provider of providers) {
      const statusElement = page.locator(`[data-provider="${provider}"] .text-sm, [id*="${provider}"] .text-sm`);
      const toggleButton = page.locator(`[data-provider="${provider}"] button, [id*="${provider}"] button`);

      const statusText = await statusElement.textContent().catch(() => 'Not found');
      const buttonText = await toggleButton.textContent().catch(() => 'Not found');

      console.log(`${provider}: Status="${statusText}" | Button="${buttonText}"`);
    }

    // Take a screenshot
    await page.screenshot({ path: 'test-sso-connections.png', fullPage: true });
    console.log('📸 Screenshot saved as test-sso-connections.png');

  } else {
    console.log('⚠️  User settings button not visible, check authentication first');
  }

  console.log('\n⏳ Keeping browser open for 30 seconds for manual inspection...');
  await page.waitForTimeout(30000);

  await browser.close();

} catch (error) {
  console.error('❌ Error during SSO connection test:', error.message);
  process.exit(1);
}