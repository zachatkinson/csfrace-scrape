const { chromium } = require('playwright');

async function debugRealOAuth() {
  console.log('🔍 Debugging real OAuth flow with event monitoring...');

  const browser = await chromium.launch({
    headless: false,
    slowMo: 1000,
    channel: 'chrome'
  });

  const page = await browser.newPage();

  // Monitor all console messages
  page.on('console', msg => {
    console.log(`🖥️  [${msg.type().toUpperCase()}] ${msg.text()}`);
  });

  // Monitor localStorage changes
  page.addInitScript(() => {
    const originalSetItem = localStorage.setItem;
    localStorage.setItem = function(key, value) {
      console.log(`📦 localStorage.setItem: ${key} = ${value}`);
      originalSetItem.call(this, key, value);
    };

    const originalRemoveItem = localStorage.removeItem;
    localStorage.removeItem = function(key) {
      console.log(`🗑️  localStorage.removeItem: ${key}`);
      originalRemoveItem.call(this, key);
    };

    // Monitor custom events
    const originalDispatchEvent = window.dispatchEvent;
    window.dispatchEvent = function(event) {
      if (event.type.includes('auth') || event.type.includes('user')) {
        console.log(`🎯 Event dispatched: ${event.type}`, event.detail || '(no detail)');
      }
      return originalDispatchEvent.call(this, event);
    };

    // Monitor event listeners
    const originalAddEventListener = window.addEventListener;
    window.addEventListener = function(type, listener, options) {
      if (type.includes('auth') || type.includes('user')) {
        console.log(`👂 Event listener added: ${type}`);
      }
      return originalAddEventListener.call(this, type, listener, options);
    };
  });

  try {
    console.log('📍 Loading https://localhost...');
    await page.goto('https://localhost', { waitUntil: 'domcontentloaded' });

    // Check initial state
    const initialState = await page.evaluate(() => {
      const signInButton = document.querySelector('#morphing-auth-button');
      const userSettingsContainer = document.querySelector('#user-settings-button-container');
      return {
        signInButtonText: signInButton?.textContent?.trim(),
        userSettingsVisible: userSettingsContainer?.offsetParent !== null,
        hasHiddenClass: userSettingsContainer?.classList.contains('hidden'),
        oauthSuccess: localStorage.getItem('oauth_success'),
        cookies: document.cookie
      };
    });

    console.log('🔐 Initial state:');
    console.log(`  Sign-in button: "${initialState.signInButtonText}"`);
    console.log(`  User settings visible: ${initialState.userSettingsVisible}`);
    console.log(`  Has hidden class: ${initialState.hasHiddenClass}`);
    console.log(`  OAuth success flag: ${initialState.oauthSuccess ? 'YES' : 'NO'}`);
    console.log(`  Cookies: ${initialState.cookies || 'none'}`);

    if (!initialState.userSettingsVisible) {
      console.log('🚀 Starting OAuth flow...');

      // Click sign in button
      await page.click('#morphing-auth-button');
      console.log('✅ Clicked sign-in button');

      // Wait for modal
      await page.waitForSelector('#auth-modal', { timeout: 5000 });
      console.log('✅ Auth modal opened');

      // Click Google OAuth button
      await page.click('button:has-text("Google")');
      console.log('✅ Clicked Google OAuth button');

      console.log('⏳ Waiting for OAuth redirect...');
      await page.waitForLoadState('domcontentloaded');

      const currentUrl = page.url();
      console.log(`📍 Current URL: ${currentUrl}`);

      if (currentUrl.includes('accounts.google.com')) {
        console.log('🎯 Successfully redirected to Google OAuth');
        console.log('👋 Please complete OAuth manually and return to the main page');
        console.log('🔍 Monitoring for OAuth completion...');

        // Monitor for return to main page
        let attempts = 0;
        const maxAttempts = 120; // 2 minutes

        while (attempts < maxAttempts) {
          const url = page.url();

          if (url === 'https://localhost/' || url === 'https://localhost') {
            console.log('🎯 Returned to main page - checking OAuth state...');

            // Wait a moment for OAuth processing
            await page.waitForTimeout(2000);

            const finalState = await page.evaluate(async () => {
              const signInButton = document.querySelector('#morphing-auth-button');
              const userSettingsContainer = document.querySelector('#user-settings-button-container');

              // Check /auth/me endpoint
              let authMeResponse = null;
              try {
                const response = await fetch('https://localhost/auth/me', {
                  method: 'GET',
                  credentials: 'include',
                  headers: { 'Accept': 'application/json' }
                });
                authMeResponse = {
                  ok: response.ok,
                  status: response.status,
                  statusText: response.statusText,
                  body: response.ok ? await response.json() : await response.text()
                };
              } catch (error) {
                authMeResponse = { error: error.message };
              }

              return {
                signInButtonText: signInButton?.textContent?.trim(),
                userSettingsVisible: userSettingsContainer?.offsetParent !== null,
                hasHiddenClass: userSettingsContainer?.classList.contains('hidden'),
                oauthSuccess: localStorage.getItem('oauth_success'),
                cookies: document.cookie,
                authMeResponse: authMeResponse
              };
            });

            console.log('📊 Final OAuth state:');
            console.log(`  Sign-in button: "${finalState.signInButtonText}"`);
            console.log(`  User settings visible: ${finalState.userSettingsVisible}`);
            console.log(`  Has hidden class: ${finalState.hasHiddenClass}`);
            console.log(`  OAuth success flag: ${finalState.oauthSuccess ? 'YES' : 'NO'}`);
            console.log(`  Cookies: ${finalState.cookies || 'none'}`);
            console.log(`  /auth/me response:`, JSON.stringify(finalState.authMeResponse, null, 2));

            if (finalState.userSettingsVisible) {
              console.log('✅ SUCCESS: OAuth completed and UI updated correctly');
            } else {
              console.log('❌ ISSUE: OAuth completed but UI not updated');
              if (finalState.authMeResponse?.ok) {
                console.log('🔍 Auth endpoint says user is authenticated but UI not updated');
              } else {
                console.log('🔍 Auth endpoint says user is NOT authenticated');
              }
            }
            break;
          }

          attempts++;
          await page.waitForTimeout(1000);
        }

        if (attempts >= maxAttempts) {
          console.log('⏱️  Timeout waiting for OAuth completion');
        }

      } else {
        console.log('❌ OAuth redirect failed or unexpected URL');
      }
    } else {
      console.log('✅ User already authenticated');
    }

  } catch (error) {
    console.error('❌ Debug error:', error.message);
  }

  console.log('🏁 OAuth debug session complete - keeping browser open for inspection');
  await new Promise(() => {}); // Keep browser open
}

debugRealOAuth().catch(console.error);