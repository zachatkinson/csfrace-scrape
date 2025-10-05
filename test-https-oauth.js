const { chromium } = require('playwright');

async function testHTTPSOAuth() {
  console.log('🔒 Testing HTTPS OAuth flow with Chrome...');

  const browser = await chromium.launch({
    headless: false,
    slowMo: 500,
    channel: 'chrome',
    // Ignore SSL certificate errors for self-signed certificate
    args: ['--ignore-certificate-errors', '--ignore-ssl-errors', '--allow-running-insecure-content']
  });

  const page = await browser.newPage();

  // Set up certificate error handling
  page.on('request', request => {
    console.log(`📤 ${request.method()} ${request.url()}`);
  });

  page.on('response', response => {
    const url = response.url();
    const status = response.status();

    if (url.includes('/auth/') || url.includes('oauth') || status >= 400) {
      console.log(`🌐 ${status} ${response.request().method()} ${url}`);
    }
  });

  // Enhanced console monitoring
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('OAuth') || text.includes('auth') || text.includes('user-logged') || text.includes('🎉')) {
      console.log(`🖥️  [${msg.type().toUpperCase()}] ${text}`);
    }
  });

  try {
    // Navigate to HTTPS localhost
    console.log('📍 Loading https://localhost...');
    await page.goto('https://localhost', {
      waitUntil: 'domcontentloaded',
      // Accept self-signed certificate
      ignoreHTTPSErrors: true
    });

    console.log('✅ HTTPS connection established');

    // Check initial state
    const initialState = await page.evaluate(() => {
      return {
        signInButton: document.querySelector('#morphing-auth-button')?.textContent?.trim(),
        userSettingsVisible: document.querySelector('#user-settings-button-container')?.offsetParent !== null
      };
    });

    console.log('🔐 Initial state:');
    console.log(`  Sign-in button: "${initialState.signInButton}"`);
    console.log(`  User settings visible: ${initialState.userSettingsVisible}`);

    // Click sign in button
    const signInButton = await page.$('#morphing-auth-button');
    if (signInButton) {
      console.log('\n=== STARTING HTTPS OAUTH FLOW ===');
      console.log('🖱️  Clicking sign in button...');
      await signInButton.click();

      // Wait for modal - try multiple selectors
      let modalFound = false;
      const modalSelectors = ['.modal-overlay', '#auth-modal', '[role="dialog"]', '.modal'];
      for (const selector of modalSelectors) {
        try {
          await page.waitForSelector(selector, { timeout: 2000 });
          console.log(`✅ Auth modal opened (${selector})`);
          modalFound = true;
          break;
        } catch {
          continue;
        }
      }

      if (!modalFound) {
        console.log('⚠️  Modal selector not found, continuing anyway...');
      }

      // Click Google OAuth
      const googleButton = await page.$('button:has-text("Google")');
      if (googleButton) {
        console.log('🖱️  Clicking Google OAuth button...');
        await googleButton.click();

        // Wait for redirect and check URL
        await page.waitForLoadState('domcontentloaded');
        const redirectUrl = page.url();
        console.log(`📍 Redirected to: ${redirectUrl}`);

        if (redirectUrl.includes('accounts.google.com')) {
          console.log('✅ Successfully redirected to Google OAuth with HTTPS!');
          console.log('\n🎉 HTTPS OAuth flow is working!');
          console.log('🔒 Google OAuth accepts the HTTPS redirect URI');
          console.log('');
          console.log('📋 Next steps:');
          console.log('1. Complete the Google OAuth flow manually');
          console.log('2. You should be redirected back to https://localhost');
          console.log('3. The authentication should complete successfully');
          console.log('');
          console.log('💡 Google Cloud Console OAuth redirect URI should be:');
          console.log('   https://localhost/auth/oauth/google/callback');

          // Keep browser open for manual OAuth completion
          console.log('⏳ Keeping browser open for manual testing...');
          await page.waitForTimeout(120000); // 2 minutes

        } else {
          console.log('❌ Did not redirect to Google OAuth');
          console.log(`Current URL: ${redirectUrl}`);
        }

      } else {
        console.log('❌ Google OAuth button not found');
      }

    } else {
      console.log('❌ Sign-in button not found');
    }

  } catch (error) {
    console.error('❌ HTTPS OAuth test error:', error);
  }

  console.log('\n🏁 HTTPS OAuth test complete');
  await browser.close();
}

testHTTPSOAuth().catch(console.error);