const { chromium } = require('playwright');

async function testOAuthStateManagement() {
  console.log('🔍 Testing Docker OAuth flow in Chrome - frontend port 3000...');

  const browser = await chromium.launch({
    headless: false,
    slowMo: 1000,
    channel: 'chrome'  // Use Chrome instead of Chromium
  });

  const page = await browser.newPage();

  // Listen for auth-related console messages
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('OAuth') || text.includes('auth') || text.includes('user-logged') || text.includes('sessionStorage') || text.includes('🎉')) {
      console.log(`🖥️  [${msg.type().toUpperCase()}] ${text}`);
    }
  });

  try {
    // Navigate to Docker frontend on correct port
    console.log('📍 Loading http://localhost:3000...');
    await page.goto('http://localhost:3000', { waitUntil: 'domcontentloaded' });

    // Check initial state
    const signInButton = await page.$('#morphing-auth-button');
    const userSettings = await page.$('#user-settings-button-container');

    console.log('🔐 Initial state:');
    console.log(`  Sign-in button: ${signInButton ? 'Found' : 'Not found'}`);
    if (signInButton) {
      const buttonText = await signInButton.textContent();
      console.log(`  Button text: "${buttonText.trim()}"`);
    }
    console.log(`  User settings: ${userSettings ? (await userSettings.isVisible() ? 'Visible' : 'Hidden') : 'Not found'}`);

    // Click sign in button
    if (signInButton) {
      console.log('🖱️  Clicking sign in button...');
      await signInButton.click();

      // Wait for modal
      await page.waitForSelector('.modal-overlay', { timeout: 5000 });
      console.log('✅ Auth modal opened');

      // Find and click Google OAuth
      const googleButton = await page.$('button:has-text("Google")');
      if (googleButton) {
        console.log('🖱️  Clicking Google OAuth button...');
        await googleButton.click();

        // Wait for redirect
        await page.waitForLoadState('domcontentloaded');
        const currentUrl = page.url();
        console.log(`📍 Current URL: ${currentUrl}`);

        if (currentUrl.includes('accounts.google.com')) {
          console.log('✅ Successfully redirected to Google OAuth');
          console.log('');
          console.log('🛑 MANUAL STEP REQUIRED:');
          console.log('1. Complete the Google OAuth flow in the browser');
          console.log('2. Wait for redirect back to app');
          console.log('3. Check console for OAuth success events');
          console.log('4. Verify sign-in button changes to user info');
          console.log('5. Verify user settings button becomes visible');
          console.log('');
          console.log('⏳ Waiting 2 minutes for manual OAuth completion...');

          // Wait for manual OAuth completion
          await page.waitForTimeout(120000);

          // Check if back at app
          const finalUrl = page.url();
          console.log(`📍 Final URL: ${finalUrl}`);

          if (finalUrl.includes('localhost')) {
            console.log('✅ Back at the app!');

            // Wait for JS to process OAuth success
            await page.waitForTimeout(3000);

            // Check sessionStorage for OAuth success flag
            const oauthFlag = await page.evaluate(() => {
              return sessionStorage.getItem('oauth_success');
            });
            console.log(`💾 OAuth success flag: ${oauthFlag ? 'Present' : 'Missing'}`);

            // Check final state
            const finalSignInButton = await page.$('#morphing-auth-button');
            const finalUserSettings = await page.$('#user-settings-button-container');

            console.log('🔐 Final state:');
            if (finalSignInButton) {
              const finalButtonText = await finalSignInButton.textContent();
              console.log(`  Sign-in button text: "${finalButtonText.trim()}"`);
            }
            console.log(`  User settings visible: ${finalUserSettings ? (await finalUserSettings.isVisible() ? 'Yes' : 'No') : 'Not found'}`);

            // Check if authentication state updated properly
            if (oauthFlag === null) {
              console.log('✅ OAuth success flag processed (removed from sessionStorage)');
            } else {
              console.log('❌ OAuth success flag still present - may not have been processed');
            }

          }
        } else {
          console.log('❌ Did not redirect to Google OAuth');
        }

      } else {
        console.log('❌ Google OAuth button not found');
      }
    } else {
      console.log('❌ Sign-in button not found');
    }

  } catch (error) {
    console.error('❌ Test error:', error);
  }

  console.log('🏁 Test complete - keeping browser open for manual inspection...');
  await page.waitForTimeout(60000);
  await browser.close();
}

testOAuthStateManagement().catch(console.error);