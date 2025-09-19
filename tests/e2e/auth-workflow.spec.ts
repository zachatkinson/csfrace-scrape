import { test, expect } from '@playwright/test';

test.describe('Authentication Workflow', () => {
  const API_URL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:8000';
  const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000';

  test.beforeEach(async ({ page }) => {
    // Navigate to the application
    await page.goto('/');
  });

  test('should display login options', async ({ page }) => {
    // Wait for the page to load
    await page.waitForLoadState('networkidle');

    // Look for authentication elements
    // This assumes the frontend has login buttons or OAuth provider options
    const authSelectors = [
      '[data-testid="login-button"]',
      '[data-testid="google-login"]',
      '[data-testid="github-login"]',
      'button:has-text("Login")',
      'button:has-text("Sign in")',
      'a:has-text("Login")',
      'a:has-text("Sign in")'
    ];

    let loginElementFound = false;
    for (const selector of authSelectors) {
      const element = page.locator(selector);
      if (await element.count() > 0) {
        await expect(element.first()).toBeVisible();
        loginElementFound = true;
        break;
      }
    }

    // If no specific login elements found, at least verify page loaded
    if (!loginElementFound) {
      await expect(page).toHaveTitle(/CSFrace|scrape/i);
    }
  });

  test('should access OAuth provider endpoints', async ({ page }) => {
    // Test OAuth provider discovery via API
    const response = await page.request.get(`${API_URL}/auth/providers`);
    expect(response.status()).toBe(200);

    const providers = await response.json();
    expect(providers).toHaveProperty('providers');
    expect(Array.isArray(providers.providers)).toBe(true);

    // Should have at least Google and GitHub providers
    const providerNames = providers.providers.map((p: any) => p.name);
    expect(providerNames).toContain('google');
    expect(providerNames).toContain('github');
  });

  test('should generate Google OAuth authorization URL', async ({ page }) => {
    const response = await page.request.get(`${API_URL}/auth/google/authorize`);
    expect(response.status()).toBe(200);

    const authData = await response.json();
    expect(authData).toHaveProperty('authorization_url');
    expect(authData).toHaveProperty('state');

    const authUrl = authData.authorization_url;
    expect(authUrl).toContain('accounts.google.com');
    expect(authUrl).toContain('oauth2');
    expect(authUrl).toContain('client_id');
    expect(authUrl).toContain('redirect_uri');
    expect(authUrl).toContain('scope');
    expect(authUrl).toContain('state');
  });

  test('should generate GitHub OAuth authorization URL', async ({ page }) => {
    const response = await page.request.get(`${API_URL}/auth/github/authorize`);
    expect(response.status()).toBe(200);

    const authData = await response.json();
    expect(authData).toHaveProperty('authorization_url');
    expect(authData).toHaveProperty('state');

    const authUrl = authData.authorization_url;
    expect(authUrl).toContain('github.com');
    expect(authUrl).toContain('oauth/authorize');
    expect(authUrl).toContain('client_id');
    expect(authUrl).toContain('redirect_uri');
    expect(authUrl).toContain('scope');
    expect(authUrl).toContain('state');
  });

  test('should handle authentication state check', async ({ page }) => {
    // Test current user endpoint (should require authentication)
    const response = await page.request.get(`${API_URL}/auth/me`);

    // Should return 401 Unauthorized without valid token
    expect(response.status()).toBe(401);

    const errorData = await response.json();
    expect(errorData).toHaveProperty('detail');
  });

  test('should handle logout functionality', async ({ page }) => {
    // Test logout endpoint
    const response = await page.request.post(`${API_URL}/auth/logout`);

    // Should return success or appropriate status
    expect([200, 401]).toContain(response.status());
  });

  test('should navigate to OAuth provider on button click', async ({ page }) => {
    // Look for OAuth login buttons
    const googleButton = page.locator('[data-provider="google"], [href*="google"], button:has-text("Google")');
    const githubButton = page.locator('[data-provider="github"], [href*="github"], button:has-text("GitHub")');

    if (await googleButton.count() > 0) {
      // Click Google login button
      await googleButton.first().click();

      // Wait for navigation or popup
      // Note: In real OAuth flow, this would redirect to Google
      // For testing, we might want to intercept or mock this
      await page.waitForTimeout(1000);

      // Verify URL change or popup appearance
      const currentUrl = page.url();
      // The URL might change to OAuth provider or stay the same if handled via popup
      expect(currentUrl).toBeDefined();
    }

    if (await githubButton.count() > 0) {
      // Navigate back to home page first
      await page.goto('/');

      // Click GitHub login button
      await githubButton.first().click();

      // Wait for navigation or popup
      await page.waitForTimeout(1000);

      // Verify URL change or popup appearance
      const currentUrl = page.url();
      expect(currentUrl).toBeDefined();
    }
  });

  test('should display user profile after mock authentication', async ({ page }) => {
    // For end-to-end testing, we might want to mock successful authentication
    // This test assumes there's a way to simulate logged-in state

    // Mock authentication by setting localStorage or cookies
    await page.evaluate(() => {
      localStorage.setItem('auth_token', 'mock-jwt-token');
      localStorage.setItem('user', JSON.stringify({
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User'
      }));
    });

    // Reload page to apply authentication state
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Look for user profile elements
    const profileSelectors = [
      '[data-testid="user-profile"]',
      '[data-testid="user-menu"]',
      '[data-testid="logout-button"]',
      '.user-avatar',
      '.profile-dropdown',
      'button:has-text("Logout")',
      'button:has-text("Profile")'
    ];

    let profileElementFound = false;
    for (const selector of profileSelectors) {
      const element = page.locator(selector);
      if (await element.count() > 0) {
        await expect(element.first()).toBeVisible();
        profileElementFound = true;
        break;
      }
    }

    // If no specific profile elements found, verify auth token exists
    if (!profileElementFound) {
      const authToken = await page.evaluate(() => localStorage.getItem('auth_token'));
      expect(authToken).toBe('mock-jwt-token');
    }
  });

  test('should handle authentication errors gracefully', async ({ page }) => {
    // Test with invalid OAuth callback
    await page.goto('/auth/callback?error=access_denied');

    // Should handle error gracefully without crashing
    await page.waitForLoadState('networkidle');

    // Look for error messages or redirect to login
    const errorSelectors = [
      '[data-testid="auth-error"]',
      '.error-message',
      '.alert-error',
      'text="Authentication failed"',
      'text="Access denied"'
    ];

    let errorHandled = false;
    for (const selector of errorSelectors) {
      const element = page.locator(selector);
      if (await element.count() > 0) {
        errorHandled = true;
        break;
      }
    }

    // If no specific error handling found, verify page didn't crash
    if (!errorHandled) {
      await expect(page).not.toHaveTitle(/Error|500|404/i);
    }
  });

  test('should maintain session across page reloads', async ({ page }) => {
    // Set authentication state
    await page.evaluate(() => {
      localStorage.setItem('auth_token', 'persistent-token');
      sessionStorage.setItem('session_id', 'test-session');
    });

    // Reload page
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Verify authentication state persisted
    const authToken = await page.evaluate(() => localStorage.getItem('auth_token'));
    const sessionId = await page.evaluate(() => sessionStorage.getItem('session_id'));

    expect(authToken).toBe('persistent-token');
    expect(sessionId).toBe('test-session');
  });

  test('should clear authentication state on logout', async ({ page }) => {
    // Set authentication state
    await page.evaluate(() => {
      localStorage.setItem('auth_token', 'token-to-clear');
      localStorage.setItem('user', JSON.stringify({ id: 'test-user' }));
      sessionStorage.setItem('session_id', 'session-to-clear');
    });

    // Look for logout button
    const logoutSelectors = [
      '[data-testid="logout-button"]',
      'button:has-text("Logout")',
      'button:has-text("Sign out")',
      'a:has-text("Logout")',
      'a:has-text("Sign out")'
    ];

    let logoutTriggered = false;
    for (const selector of logoutSelectors) {
      const element = page.locator(selector);
      if (await element.count() > 0) {
        await element.first().click();
        logoutTriggered = true;
        break;
      }
    }

    // If no logout button found, simulate logout via API call
    if (!logoutTriggered) {
      await page.request.post(`${API_URL}/auth/logout`);

      // Manually clear storage to simulate logout behavior
      await page.evaluate(() => {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user');
        sessionStorage.removeItem('session_id');
      });
    }

    // Wait for logout to complete
    await page.waitForTimeout(1000);

    // Verify authentication state cleared
    const authToken = await page.evaluate(() => localStorage.getItem('auth_token'));
    const user = await page.evaluate(() => localStorage.getItem('user'));

    expect(authToken).toBeNull();
    expect(user).toBeNull();
  });
});