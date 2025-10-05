const { chromium } = require('playwright');

async function testOAuthLocalStorage() {
  console.log('🔒 Testing HTTPS OAuth flow with localStorage fix...');

  const browser = await chromium.launch({
    headless: false,
    slowMo: 1000,
    channel: 'chrome',
  });

  const page = await browser.newPage();

  // Enhanced console monitoring
  page.on('console', msg => {
    const text = msg.text();
    console.log(`🖥️  [${msg.type().toUpperCase()}] ${text}`);
  });

  // Monitor localStorage changes
  page.addInitScript(() => {
    const originalSetItem = window.localStorage.setItem;
    window.localStorage.setItem = function(key, value) {
      console.log(`📦 localStorage.setItem: ${key} = ${value}`);
      originalSetItem.call(this, key, value);
    };

    const originalRemoveItem = window.localStorage.removeItem;
    window.localStorage.removeItem = function(key) {
      console.log(`🗑️  localStorage.removeItem: ${key}`);
      originalRemoveItem.call(this, key);
    };

    // Monitor storage events
    window.addEventListener('storage', (event) => {
      console.log(`🔄 Storage event - key: ${event.key}, newValue: ${event.newValue}`);
    });
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
        hasAuthModal: !!document.querySelector('#auth-modal'),
        oauthSuccess: localStorage.getItem('oauth_success')
      };
    });

    console.log('🔐 Initial authentication state:');
    console.log(`  Sign-in button text: "${initialState.signInButton}"`);
    console.log(`  User settings visible: ${initialState.userSettingsVisible}`);
    console.log(`  OAuth success in localStorage: ${initialState.oauthSuccess ? 'Yes' : 'No'}`);

    if (initialState.userSettingsVisible) {
      console.log('✅ User already authenticated');
      console.log('🏁 Test complete - user is already logged in');
    } else {
      console.log('⏳ User not authenticated - starting OAuth flow...');

      // Start OAuth flow
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

      // Wait for redirect
      console.log('⏳ Waiting for OAuth redirect...');
      await page.waitForLoadState('domcontentloaded');

      const currentUrl = page.url();
      console.log(`📍 Current URL: ${currentUrl}`);

      if (currentUrl.includes('accounts.google.com')) {
        console.log('✅ Successfully redirected to Google OAuth!');
        console.log('📋 Complete OAuth manually and return to see localStorage changes');
        console.log('🔍 Monitoring localStorage and console for OAuth completion...');

        // Keep browser open and monitor for OAuth completion
        let checkCount = 0;
        const maxChecks = 120; // 2 minutes

        const monitorOAuth = async () => {
          while (checkCount < maxChecks) {
            try {
              const currentUrl = page.url();
              if (currentUrl === 'https://localhost/') {
                console.log('🎯 Returned to main page - checking OAuth state...');

                // Check localStorage for oauth_success
                const oauthData = await page.evaluate(() => {
                  return {
                    oauthSuccess: localStorage.getItem('oauth_success'),
                    userSettingsVisible: document.querySelector('#user-settings-button-container')?.offsetParent !== null
                  };
                });

                console.log('📊 OAuth completion state:');
                console.log(`  oauth_success in localStorage: ${oauthData.oauthSuccess ? 'Yes' : 'No'}`);
                console.log(`  User settings visible: ${oauthData.userSettingsVisible}`);

                if (oauthData.userSettingsVisible) {
                  console.log('🎉 OAuth flow completed successfully!');
                  console.log('✅ UI state updated correctly');
                  break;
                } else if (oauthData.oauthSuccess) {
                  console.log('⚠️  OAuth success flag found but UI not updated - investigating...');
                  // Check if authentication endpoint works
                  const authCheck = await page.evaluate(async () => {
                    try {
                      const response = await fetch('https://localhost/auth/me', {
                        method: 'GET',
                        credentials: 'include',
                        headers: { 'Accept': 'application/json' }
                      });
                      return {
                        status: response.status,
                        ok: response.ok,
                        statusText: response.statusText
                      };
                    } catch (error) {
                      return { error: error.message };
                    }
                  });
                  console.log('🔍 Auth endpoint check:', authCheck);
                }
              }
            } catch (error) {
              console.log('⚠️  Error monitoring OAuth:', error.message);
            }

            checkCount++;
            await page.waitForTimeout(1000);
          }

          if (checkCount >= maxChecks) {
            console.log('⏱️  Monitoring timeout reached');
          }
        };

        await monitorOAuth();
      } else {
        console.log('❌ OAuth redirect failed');
        console.log(`Expected: accounts.google.com, Got: ${currentUrl}`);
      }
    }

  } catch (error) {
    console.error('❌ OAuth test error:', error.message);
  }

  console.log('🏁 OAuth localStorage test session complete');
  // Keep browser open for manual inspection
  console.log('Browser will remain open - press Ctrl+C when done');
  await new Promise(() => {}); // Keep alive
}

testOAuthLocalStorage().catch(console.error);