#!/usr/bin/env node

/**
 * Test SSO Connection Fix - Verify that SSO services show correct connection status
 * after frontend logic fix (should not show all services as connected)
 */

import { chromium } from 'playwright';

const BASE_URL = 'https://localhost';

console.log('🔗 Testing SSO Connection Status Fix...');

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

  // Step 2: Simulate OAuth authentication with a Google user
  console.log('\n🔐 Step 2: Simulate OAuth authentication (Google user)...');
  await page.evaluate(() => {
    // Simulate what happens after OAuth callback - dispatch the auth-success event
    console.log('🔐 Simulating Google OAuth login...');
    window.dispatchEvent(new CustomEvent('auth-success', {
      detail: {
        user: {
          id: 'test-user',
          email: 'test@gmail.com',  // Google email to test domain matching
          name: 'Test User'
        },
        token: 'test-token-12345'
      }
    }));

    console.log('🔐 Auth-success event dispatched');
  });

  await page.waitForTimeout(2000);

  // Step 3: Open user settings modal using the morphing auth button
  console.log('\n⚙️  Step 3: Opening User Settings Modal...');

  // Wait for auth button to morph to logout state
  await page.waitForSelector('#morphing-auth-button', { state: 'visible' });

  // Check if auth button shows "Log Out" (indicating successful auth)
  const authButtonText = await page.locator('#auth-text').textContent();
  console.log(`Auth button text: "${authButtonText}"`);

  if (authButtonText === 'Log Out') {
    console.log('✅ Authentication successful, looking for user settings...');

    // Look for user settings button
    const userSettingsButton = page.locator('#user-settings-button, [data-testid="user-settings"], button[class*="user-settings"]').first();

    const isVisible = await userSettingsButton.isVisible();
    console.log(`User settings button visible: ${isVisible}`);

    if (isVisible) {
      await userSettingsButton.click();
      await page.waitForTimeout(2000);

      // Step 4: Check SSO provider connection status
      console.log('\n📋 Step 4: Checking SSO provider connection status...');

      const providers = ['google', 'microsoft', 'github', 'facebook', 'apple'];
      const results = {};

      for (const provider of providers) {
        const statusElement = page.locator(`[data-provider="${provider}"] .text-sm, [id*="${provider}"] .text-sm`).first();
        const toggleButton = page.locator(`[data-provider="${provider}"] button, [id*="${provider}"] button`).first();

        const statusText = await statusElement.textContent().catch(() => 'Not found');
        const buttonText = await toggleButton.textContent().catch(() => 'Not found');

        results[provider] = { status: statusText, button: buttonText };
        console.log(`${provider}: Status="${statusText}" | Button="${buttonText}"`);
      }

      // Step 5: Verify the fix - should NOT show all services as connected
      console.log('\n✅ Step 5: Verifying connection status fix...');

      const connectedProviders = [];
      const notConnectedProviders = [];

      for (const [provider, data] of Object.entries(results)) {
        if (data.status.toLowerCase().includes('connected') || data.button.toLowerCase().includes('disconnect')) {
          connectedProviders.push(provider);
        } else if (data.status.toLowerCase().includes('not connected') || data.button.toLowerCase().includes('connect')) {
          notConnectedProviders.push(provider);
        }
      }

      console.log(`Connected providers: [${connectedProviders.join(', ')}]`);
      console.log(`Not connected providers: [${notConnectedProviders.join(', ')}]`);

      // Test Results
      if (connectedProviders.length === 0) {
        console.log('🎯 ✅ EXCELLENT: No false positives - all services correctly show as "Not connected"');
        console.log('🎯 ✅ Fix successful: Backend endpoint properly returns no connections when none exist');
      } else if (connectedProviders.length === 1 && connectedProviders.includes('google')) {
        console.log('🎯 ✅ GOOD: Only Google shows as connected (expected based on email domain)');
        console.log('🎯 ✅ Fix successful: Other providers correctly show as "Not connected"');
      } else if (connectedProviders.length === providers.length) {
        console.log('🎯 ❌ ISSUE: All services still show as connected - fix may not be working');
        console.log('🎯 ❌ Frontend logic may still have false positive issue');
      } else {
        console.log('🎯 ⚠️  PARTIAL: Some unexpected connection states detected');
      }

      // Take a screenshot
      await page.screenshot({ path: 'test-sso-connection-fix.png', fullPage: true });
      console.log('📸 Screenshot saved as test-sso-connection-fix.png');

    } else {
      console.log('⚠️  User settings button not visible after authentication');
    }
  } else {
    console.log('⚠️  Authentication may not have worked - auth button still shows "Sign In"');
  }

  console.log('\n⏳ Keeping browser open for 15 seconds for manual inspection...');
  await page.waitForTimeout(15000);

  await browser.close();

} catch (error) {
  console.error('❌ Error during SSO connection fix test:', error.message);
  process.exit(1);
}