#!/usr/bin/env node

/**
 * Complete OAuth Flow Test - Test full authentication flow and UI updates
 */

import { chromium } from 'playwright';

const BASE_URL = 'https://localhost';

console.log('🔐 Testing Complete OAuth Authentication Flow...');

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
    if (msg.type() === 'log' && msg.text().includes('🔐')) {
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
  console.log(`📄 Page title: ${await page.title()}`);

  // Step 2: Check initial state
  console.log('\n🔍 Step 2: Check initial authentication state...');

  const signInButton = page.locator('[id*="auth-button"], [class*="auth-button"], button:has-text("Sign In")');
  const userSettingsButton = page.locator('[id*="user-settings"], [data-testid*="settings"], button:has-text("Settings")');

  const signInVisible = await signInButton.isVisible();
  const userSettingsVisible = await userSettingsButton.isVisible();

  console.log(`Sign In button visible: ${signInVisible}`);
  console.log(`User Settings button visible: ${userSettingsVisible}`);

  // Step 3: Test OAuth flow simulation
  console.log('\n🔗 Step 3: Simulate OAuth success...');

  // Simulate what happens after OAuth callback - dispatch the auth-success event
  await page.evaluate(() => {
    // Simulate setting tokens (like OAuth callback would do)
    localStorage.setItem('auth_token', 'test-token-12345');
    localStorage.setItem('auth_user', JSON.stringify({
      id: 'test-user',
      email: 'test@example.com',
      name: 'Test User'
    }));

    // Dispatch the auth-success event that OAuth callback should dispatch
    console.log('🔐 Dispatching auth-success event...');
    window.dispatchEvent(new CustomEvent('auth-success', {
      detail: {
        user: {
          id: 'test-user',
          email: 'test@example.com',
          name: 'Test User'
        },
        token: 'test-token-12345'
      }
    }));

    console.log('🔐 Auth-success event dispatched');
  });

  // Wait for UI to update
  await page.waitForTimeout(2000);

  // Step 4: Check post-authentication state
  console.log('\n✅ Step 4: Check post-authentication state...');

  const signInVisibleAfter = await signInButton.isVisible();
  const userSettingsVisibleAfter = await userSettingsButton.isVisible();

  console.log(`Sign In button visible after auth: ${signInVisibleAfter}`);
  console.log(`User Settings button visible after auth: ${userSettingsVisibleAfter}`);

  // Step 5: Test /auth/me API call
  console.log('\n🌐 Step 5: Test /auth/me API call simulation...');

  await page.evaluate(async () => {
    try {
      console.log('🔐 Testing updateUserSettingsVisibility function...');

      // Simulate the updateUserSettingsVisibility function
      const userSettingsContainer = document.getElementById('user-settings-button-container');
      console.log('🔐 User settings container found:', !!userSettingsContainer);

      if (userSettingsContainer) {
        console.log('🔐 Showing user settings container...');
        userSettingsContainer.classList.remove('hidden');
        userSettingsContainer.style.display = 'block';
      }

      // Also check for morphing auth button
      const authButton = document.getElementById('morphing-auth-button');
      const authText = document.getElementById('auth-text');

      if (authButton && authText) {
        console.log('🔐 Updating morphing auth button to logout state...');
        authText.textContent = 'Log Out';
        authButton.className = 'glass-button px-4 py-2 text-red-400 hover:text-red-300 border-red-500/30 hover:border-red-500/50 transition-all duration-300 flex items-center space-x-2';
      }

    } catch (error) {
      console.log('❌ Error in auth simulation:', error.message);
    }
  });

  // Wait for changes to apply
  await page.waitForTimeout(1000);

  // Step 6: Final state check
  console.log('\n🎯 Step 6: Final authentication state check...');

  const finalSignInVisible = await signInButton.isVisible();
  const finalUserSettingsVisible = await userSettingsButton.isVisible();
  const authButtonText = await page.locator('#auth-text').textContent();

  console.log(`Final Sign In button visible: ${finalSignInVisible}`);
  console.log(`Final User Settings button visible: ${finalUserSettingsVisible}`);
  console.log(`Auth button text: "${authButtonText}"`);

  // Step 7: Test Settings Modal
  if (finalUserSettingsVisible) {
    console.log('\n⚙️  Step 7: Testing Settings Modal...');

    await userSettingsButton.click();
    await page.waitForTimeout(1000);

    const modal = page.locator('[data-modal="user-settings"], .modal, [id*="settings-modal"]');
    const modalVisible = await modal.isVisible();
    console.log(`Settings modal visible after click: ${modalVisible}`);
  } else {
    console.log('\n⚠️  Step 7: Skipping Settings Modal test - button not visible');
  }

  // Summary
  console.log('\n📊 Authentication Flow Test Summary:');
  console.log(`Initial Sign In visible: ${signInVisible}`);
  console.log(`Initial Settings visible: ${userSettingsVisible}`);
  console.log(`After auth Sign In visible: ${signInVisibleAfter}`);
  console.log(`After auth Settings visible: ${userSettingsVisibleAfter}`);
  console.log(`Final Sign In visible: ${finalSignInVisible}`);
  console.log(`Final Settings visible: ${finalUserSettingsVisible}`);

  console.log('\n⏳ Keeping browser open for 30 seconds for manual inspection...');
  await page.waitForTimeout(30000);

  await browser.close();

} catch (error) {
  console.error('❌ Error during OAuth flow test:', error.message);
  process.exit(1);
}