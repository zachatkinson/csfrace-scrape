const { chromium } = require('playwright');

async function monitorOAuthState() {
  console.log('🔍 Monitoring OAuth state and authentication changes...');

  const browser = await chromium.launch({
    headless: false,
    slowMo: 500,
    channel: 'chrome'
  });

  const page = await browser.newPage();

  // Comprehensive console monitoring
  page.on('console', msg => {
    console.log(`🖥️  [${msg.type().toUpperCase()}] ${msg.text()}`);
  });

  // Network monitoring focused on auth endpoints
  page.on('response', response => {
    const url = response.url();
    const status = response.status();

    if (url.includes('/auth/') || url.includes('oauth') || url.includes('/me') || status >= 400) {
      console.log(`🌐 ${status} ${response.request().method()} ${url}`);
    }
  });

  try {
    // Navigate to localhost
    console.log('📍 Loading http://localhost...');
    await page.goto('http://localhost', { waitUntil: 'domcontentloaded' });

    console.log('\n=== CURRENT STATE ANALYSIS ===');

    // Check current authentication state
    const currentState = await page.evaluate(() => {
      return {
        oauth_success: sessionStorage.getItem('oauth_success'),
        auth_token: localStorage.getItem('auth_token') || sessionStorage.getItem('auth_token'),
        cookies: document.cookie,

        // Check UI elements
        signInButton: {
          exists: !!document.querySelector('#morphing-auth-button'),
          text: document.querySelector('#morphing-auth-button')?.textContent?.trim() || 'Not found',
          visible: document.querySelector('#morphing-auth-button')?.offsetParent !== null
        },

        userSettings: {
          exists: !!document.querySelector('#user-settings-button-container'),
          visible: document.querySelector('#user-settings-button-container')?.offsetParent !== null
        }
      };
    });

    console.log('💾 Current storage state:');
    console.log('  oauth_success:', currentState.oauth_success);
    console.log('  auth_token:', currentState.auth_token ? 'Present' : 'Missing');
    console.log('  cookies:', currentState.cookies || 'None');

    console.log('🔐 Current UI state:');
    console.log(`  Sign-in button: ${currentState.signInButton.exists ? 'Found' : 'Missing'}`);
    console.log(`  Button text: "${currentState.signInButton.text}"`);
    console.log(`  Button visible: ${currentState.signInButton.visible}`);
    console.log(`  User settings visible: ${currentState.userSettings.visible}`);

    // If there's an oauth_success flag, the OAuth might have completed but not processed
    if (currentState.oauth_success) {
      console.log('\n⚠️  OAuth success flag found but not processed!');
      try {
        const oauthData = JSON.parse(currentState.oauth_success);
        console.log('📊 OAuth data:', oauthData);
      } catch (e) {
        console.log('❌ Failed to parse OAuth data:', e.message);
      }

      // Wait to see if the events process
      console.log('⏳ Waiting 5 seconds to see if OAuth events process...');
      await page.waitForTimeout(5000);

      // Check again
      const afterWaitState = await page.evaluate(() => {
        return {
          oauth_success: sessionStorage.getItem('oauth_success'),
          signInButtonText: document.querySelector('#morphing-auth-button')?.textContent?.trim() || 'Not found',
          userSettingsVisible: document.querySelector('#user-settings-button-container')?.offsetParent !== null
        };
      });

      console.log('\n=== STATE AFTER WAITING ===');
      console.log('  OAuth success flag:', afterWaitState.oauth_success ? 'Still present' : 'Processed (removed)');
      console.log(`  Sign-in button text: "${afterWaitState.signInButtonText}"`);
      console.log(`  User settings visible: ${afterWaitState.userSettingsVisible}`);
    }

    // Check if user is actually authenticated by testing /auth/me endpoint
    console.log('\n=== BACKEND AUTHENTICATION CHECK ===');
    try {
      const authCheckResponse = await page.evaluate(async () => {
        const response = await fetch('http://localhost/auth/me', {
          method: 'GET',
          credentials: 'include',
          headers: {
            'Accept': 'application/json',
          },
        });

        return {
          status: response.status,
          ok: response.ok,
          text: await response.text()
        };
      });

      console.log(`🔍 /auth/me response: ${authCheckResponse.status}`);
      if (authCheckResponse.ok) {
        try {
          const userData = JSON.parse(authCheckResponse.text);
          console.log('✅ User is authenticated:', userData);
        } catch (e) {
          console.log('✅ User is authenticated (non-JSON response):', authCheckResponse.text);
        }
      } else {
        console.log('❌ User is not authenticated:', authCheckResponse.text);
      }
    } catch (error) {
      console.log('❌ Failed to check authentication:', error.message);
    }

    // Monitor for real-time changes
    console.log('\n=== MONITORING FOR CHANGES ===');
    console.log('Monitoring for authentication state changes for 30 seconds...');

    // Set up monitoring for storage changes
    await page.evaluate(() => {
      const originalSetItem = Storage.prototype.setItem;
      const originalRemoveItem = Storage.prototype.removeItem;

      Storage.prototype.setItem = function(key, value) {
        console.log(`🔄 Storage SET: ${key} = ${value}`);
        return originalSetItem.apply(this, arguments);
      };

      Storage.prototype.removeItem = function(key) {
        console.log(`🔄 Storage REMOVE: ${key}`);
        return originalRemoveItem.apply(this, arguments);
      };

      // Monitor for custom events
      window.addEventListener('user-logged-in', (event) => {
        console.log('🎉 EVENT: user-logged-in', event.detail);
      });

      window.addEventListener('auth-success', (event) => {
        console.log('🎉 EVENT: auth-success', event.detail);
      });
    });

    // Wait and check periodically for changes
    for (let i = 0; i < 6; i++) {
      await page.waitForTimeout(5000);

      const monitorState = await page.evaluate(() => {
        return {
          signInButtonText: document.querySelector('#morphing-auth-button')?.textContent?.trim() || 'Not found',
          userSettingsVisible: document.querySelector('#user-settings-button-container')?.offsetParent !== null,
          oauthFlag: sessionStorage.getItem('oauth_success')
        };
      });

      console.log(`⏰ Check ${i + 1}/6: Button="${monitorState.signInButtonText}", Settings=${monitorState.userSettingsVisible}, OAuth=${monitorState.oauthFlag ? 'Present' : 'None'}`);
    }

  } catch (error) {
    console.error('❌ Monitor error:', error);
  }

  console.log('\n🏁 Monitoring complete - keeping browser open for inspection...');
  await page.waitForTimeout(30000);
  await browser.close();
}

monitorOAuthState().catch(console.error);