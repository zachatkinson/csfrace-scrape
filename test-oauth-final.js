const { chromium } = require('playwright');

async function testFinalOAuthFlow() {
  console.log('🔒 Testing complete HTTPS OAuth flow...');

  const browser = await chromium.launch({
    headless: false,
    slowMo: 1000,
    channel: 'chrome',
    // No need for certificate flags now that HTTPS is trusted
  });

  const page = await browser.newPage();

  // Enhanced request/response monitoring
  page.on('request', request => {
    const url = request.url();
    if (url.includes('/auth/') || url.includes('oauth') || url.includes('google')) {
      console.log(`📤 ${request.method()} ${url}`);
    }
  });

  page.on('response', response => {
    const url = response.url();
    const status = response.status();

    if (url.includes('/auth/') || url.includes('oauth') || url.includes('google') || status >= 400) {
      console.log(`🌐 ${status} ${response.request().method()} ${url}`);
    }
  });

  // Console monitoring for OAuth events
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('OAuth') || text.includes('auth') || text.includes('user-logged') || text.includes('🎉') || text.includes('ERROR') || text.includes('error')) {
      console.log(`🖥️  [${msg.type().toUpperCase()}] ${text}`);
    }
  });

  try {
    console.log('📍 Loading https://localhost...');
    await page.goto('https://localhost', {
      waitUntil: 'domcontentloaded'
    });

    console.log('✅ HTTPS page loaded successfully');

    // Check initial authentication state
    const initialState = await page.evaluate(() => {
      return {
        signInButton: document.querySelector('#morphing-auth-button')?.textContent?.trim(),
        userSettingsVisible: document.querySelector('#user-settings-button-container')?.offsetParent !== null,
        hasAuthModal: !!document.querySelector('#auth-modal')
      };
    });

    console.log('🔐 Initial authentication state:');
    console.log(`  Sign-in button text: "${initialState.signInButton}"`);
    console.log(`  User settings visible: ${initialState.userSettingsVisible}`);
    console.log(`  Auth modal present: ${initialState.hasAuthModal}`);

    if (initialState.userSettingsVisible) {
      console.log('✅ User already authenticated - testing logout/login cycle');

      // Click logout first if already authenticated
      const logoutButton = await page.$('#morphing-auth-button');
      if (logoutButton) {
        await logoutButton.click();
        await page.waitForTimeout(2000);
      }
    }

    // Start OAuth flow
    console.log('\n=== STARTING OAUTH FLOW ===');
    const signInButton = await page.waitForSelector('#morphing-auth-button', { timeout: 5000 });

    console.log('🖱️  Clicking sign in button...');
    await signInButton.click();

    // Wait for modal
    console.log('⏳ Waiting for auth modal...');
    await page.waitForSelector('#auth-modal', { timeout: 5000 });
    console.log('✅ Auth modal opened');

    // Click Google OAuth
    console.log('🖱️  Clicking Google OAuth button...');
    const googleButton = await page.waitForSelector('button:has-text("Google")', { timeout: 5000 });
    await googleButton.click();

    // Monitor for redirect
    console.log('⏳ Monitoring OAuth redirect...');
    await page.waitForLoadState('domcontentloaded');

    const currentUrl = page.url();
    console.log(`📍 Current URL: ${currentUrl}`);

    if (currentUrl.includes('accounts.google.com')) {
      console.log('✅ Successfully redirected to Google OAuth!');
      console.log('🔒 HTTPS OAuth redirect working perfectly');

      // Check for any errors on Google's page
      const pageTitle = await page.title();
      const hasError = currentUrl.includes('error') || pageTitle.toLowerCase().includes('error');

      if (hasError) {
        console.log('❌ Google OAuth error detected');
        const errorText = await page.textContent('body').catch(() => 'Could not read error');
        console.log(`Error details: ${errorText.substring(0, 200)}...`);
      } else {
        console.log('✅ Google OAuth page loaded successfully');
        console.log('📋 Manual steps:');
        console.log('1. Complete Google sign-in manually');
        console.log('2. You should be redirected back to https://localhost');
        console.log('3. Check if user settings button appears (authentication success)');
      }

      // Keep browser open for manual completion
      console.log('\n⏳ Keeping browser open for manual OAuth completion...');
      console.log('Press Ctrl+C to exit when done testing');

      // Wait indefinitely for manual testing
      await new Promise(() => {});

    } else {
      console.log('❌ OAuth redirect failed');
      console.log(`Expected: accounts.google.com, Got: ${currentUrl}`);

      // Check for any error messages on page
      const errorElements = await page.$$eval('[class*="error"], [class*="Error"], .alert, .warning',
        elements => elements.map(el => el.textContent).filter(text => text?.trim())
      ).catch(() => []);

      if (errorElements.length > 0) {
        console.log('🔍 Found error messages:');
        errorElements.forEach(error => console.log(`  - ${error}`));
      }
    }

  } catch (error) {
    console.error('❌ OAuth test error:', error.message);

    // Take screenshot for debugging
    try {
      await page.screenshot({ path: 'oauth-error.png', fullPage: true });
      console.log('📸 Error screenshot saved as oauth-error.png');
    } catch (screenshotError) {
      console.log('Could not save screenshot');
    }
  }

  // Don't close browser automatically for manual testing
  console.log('\n🏁 OAuth test session started - browser will remain open for manual testing');
}

testFinalOAuthFlow().catch(console.error);