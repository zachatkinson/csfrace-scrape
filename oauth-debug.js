const { chromium } = require('playwright');

async function debugOAuthFlow() {
  console.log('🔍 Debugging OAuth flow at localhost (nginx proxy)...');

  const browser = await chromium.launch({
    headless: false,
    slowMo: 1000,
    channel: 'chrome'
  });

  const page = await browser.newPage();

  // Comprehensive console monitoring
  page.on('console', msg => {
    console.log(`🖥️  [${msg.type().toUpperCase()}] ${msg.text()}`);
  });

  // Network monitoring
  page.on('response', response => {
    const url = response.url();
    const status = response.status();

    if (url.includes('/auth/') || url.includes('oauth') || url.includes('/me') || status >= 400) {
      console.log(`🌐 ${status} ${response.request().method()} ${url}`);
    }
  });

  // Request monitoring
  page.on('request', request => {
    const url = request.url();
    if (url.includes('/auth/') || url.includes('oauth')) {
      console.log(`📤 ${request.method()} ${url}`);
    }
  });

  try {
    // Navigate to localhost (nginx proxy)
    console.log('📍 Loading http://localhost (nginx proxy)...');
    await page.goto('http://localhost', { waitUntil: 'domcontentloaded' });

    console.log('\n=== INITIAL STATE CHECK ===');

    // Check initial authentication state
    const initialSessionStorage = await page.evaluate(() => {
      return {
        oauth_success: sessionStorage.getItem('oauth_success'),
        auth_token: localStorage.getItem('auth_token') || sessionStorage.getItem('auth_token'),
        cookies: document.cookie
      };
    });
    console.log('💾 Initial storage state:', initialSessionStorage);

    // Check UI elements
    const signInButton = await page.$('#morphing-auth-button');
    const userSettings = await page.$('#user-settings-button-container');

    console.log('🔐 Initial UI state:');
    console.log(`  Sign-in button: ${signInButton ? 'Found' : 'Missing'}`);
    if (signInButton) {
      const buttonText = await signInButton.textContent();
      console.log(`  Button text: "${buttonText.trim()}"`);
    }
    console.log(`  User settings visible: ${userSettings ? (await userSettings.isVisible()) : false}`);

    if (signInButton) {
      console.log('\n=== STARTING OAUTH FLOW ===');
      console.log('🖱️  Clicking sign in button...');
      await signInButton.click();

      // Wait for auth modal - try different selectors
      try {
        await page.waitForSelector('.modal-overlay', { timeout: 3000 });
        console.log('✅ Modal overlay found');
      } catch {
        // Try other modal selectors
        const modalSelectors = ['#auth-modal', '[role="dialog"]', '.modal', '.auth-modal'];
        for (const selector of modalSelectors) {
          const modal = await page.$(selector);
          if (modal) {
            console.log(`✅ Modal found with selector: ${selector}`);
            break;
          }
        }
      }

      // Look for Google OAuth button
      const googleButton = await page.$('button:has-text("Google")');
      if (googleButton) {
        console.log('✅ Google OAuth button found');
        console.log('🖱️  Clicking Google OAuth button...');
        await googleButton.click();

        // Wait for redirect
        console.log('⏳ Waiting for OAuth redirect...');
        await page.waitForLoadState('domcontentloaded');

        const oauthUrl = page.url();
        console.log(`📍 OAuth URL: ${oauthUrl}`);

        if (oauthUrl.includes('accounts.google.com')) {
          console.log('✅ Successfully redirected to Google OAuth');
          console.log('\n=== MANUAL OAUTH REQUIRED ===');
          console.log('Please complete the Google OAuth flow manually');
          console.log('Monitoring for return to localhost...\n');

          // Wait for OAuth completion and return
          let returnedToApp = false;
          let attempts = 0;
          const maxAttempts = 60; // 2 minutes

          while (!returnedToApp && attempts < maxAttempts) {
            await page.waitForTimeout(2000);
            attempts++;

            const currentUrl = page.url();
            console.log(`⏳ [${attempts}/${maxAttempts}] Current URL: ${currentUrl}`);

            if (currentUrl.includes('localhost') && !currentUrl.includes('accounts.google.com')) {
              returnedToApp = true;
              console.log('\n=== RETURNED TO APP ===');
              console.log('✅ Back at localhost after OAuth!');

              // Wait for any OAuth processing
              console.log('⏳ Waiting for OAuth success processing...');
              await page.waitForTimeout(3000);

              // Check sessionStorage after OAuth
              const postOAuthStorage = await page.evaluate(() => {
                return {
                  oauth_success: sessionStorage.getItem('oauth_success'),
                  auth_token: localStorage.getItem('auth_token') || sessionStorage.getItem('auth_token'),
                  cookies: document.cookie
                };
              });
              console.log('💾 Post-OAuth storage state:', postOAuthStorage);

              // Check final UI state
              const finalSignInButton = await page.$('#morphing-auth-button');
              const finalUserSettings = await page.$('#user-settings-button-container');

              console.log('\n=== FINAL STATE CHECK ===');
              if (finalSignInButton) {
                const finalButtonText = await finalSignInButton.textContent();
                console.log(`🔐 Sign-in button text: "${finalButtonText.trim()}"`);
              }
              console.log(`🔐 User settings visible: ${finalUserSettings ? (await finalUserSettings.isVisible()) : false}`);

              // Analyze the issue
              console.log('\n=== ANALYSIS ===');
              if (postOAuthStorage.oauth_success) {
                console.log('❌ OAuth success flag still present - event may not have fired');
              } else {
                console.log('✅ OAuth success flag processed (removed)');
              }

              if (postOAuthStorage.auth_token) {
                console.log('✅ Auth token present in storage');
              } else {
                console.log('❌ No auth token found in storage');
              }

              if (postOAuthStorage.cookies.includes('auth')) {
                console.log('✅ Auth cookies present');
              } else {
                console.log('❌ No auth cookies found');
              }

              break;
            }
          }

          if (!returnedToApp) {
            console.log('❌ Timed out waiting for return to app');
          }

        } else {
          console.log('❌ Did not redirect to Google OAuth');
          console.log(`Current URL: ${page.url()}`);
        }

      } else {
        console.log('❌ Google OAuth button not found');

        // Debug: list all buttons
        const allButtons = await page.$$eval('button', buttons =>
          buttons.map(btn => ({
            text: btn.textContent?.trim(),
            id: btn.id,
            visible: btn.offsetParent !== null
          })).filter(btn => btn.visible)
        );
        console.log('Available visible buttons:', allButtons);
      }

    } else {
      console.log('❌ Sign-in button not found');
    }

  } catch (error) {
    console.error('❌ Test error:', error);
  }

  console.log('\n🏁 Debug session complete - keeping browser open for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
}

debugOAuthFlow().catch(console.error);