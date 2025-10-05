#!/usr/bin/env node

/**
 * Test OAuth Connections Endpoint - Backend API Test
 * Tests the new /auth/oauth/connections endpoint directly
 */

import { chromium } from 'playwright';

const BASE_URL = 'https://localhost';

console.log('🔗 Testing OAuth Connections Backend Endpoint...');

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
    if (msg.type() === 'log' && (msg.text().includes('OAuth') || msg.text().includes('connections'))) {
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

  // Step 2: Simulate OAuth authentication to get cookies
  console.log('\n🔐 Step 2: Simulate OAuth authentication...');
  await page.evaluate(() => {
    // Simulate OAuth tokens being set (like OAuth callback would do)
    localStorage.setItem('auth_token', 'test-token-12345');
    localStorage.setItem('auth_user', JSON.stringify({
      id: 'test-user',
      email: 'test@gmail.com',
      name: 'Test User'
    }));

    // Dispatch auth-success event
    console.log('🔐 Dispatching auth-success event...');
    window.dispatchEvent(new CustomEvent('auth-success', {
      detail: {
        user: {
          id: 'test-user',
          email: 'test@gmail.com',
          name: 'Test User'
        }
      }
    }));
  });

  await page.waitForTimeout(2000);

  // Step 3: Test the backend endpoint directly via browser fetch
  console.log('\n🌐 Step 3: Testing /auth/oauth/connections endpoint directly...');
  
  const endpointResult = await page.evaluate(async () => {
    try {
      console.log('🔗 Making request to /auth/oauth/connections...');
      
      const response = await fetch('/auth/oauth/connections', {
        method: 'GET',
        credentials: 'include', // Include HTTP-only cookies
        headers: {
          'Accept': 'application/json',
        },
      });
      
      console.log('🔗 Response status:', response.status);
      console.log('🔗 Response headers:', Object.fromEntries(response.headers.entries()));
      
      const responseText = await response.text();
      console.log('🔗 Response body (raw):', responseText);
      
      if (response.ok) {
        try {
          const data = JSON.parse(responseText);
          return {
            success: true,
            status: response.status,
            data: data
          };
        } catch (parseError) {
          return {
            success: false,
            status: response.status,
            error: 'Failed to parse JSON response',
            responseText: responseText
          };
        }
      } else {
        return {
          success: false,
          status: response.status,
          error: responseText
        };
      }
    } catch (error) {
      console.log('❌ Fetch error:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  });

  console.log('\n📊 OAuth Connections Endpoint Test Results:');
  if (endpointResult.success) {
    console.log('✅ Endpoint responded successfully!');
    console.log('📄 Response data:', JSON.stringify(endpointResult.data, null, 2));
    
    if (Array.isArray(endpointResult.data)) {
      console.log(`📋 Found ${endpointResult.data.length} OAuth providers:`);
      endpointResult.data.forEach(provider => {
        const status = provider.connected ? '✅ Connected' : '❌ Not Connected';
        console.log(`  • ${provider.provider}: ${status}`);
        if (provider.connected && provider.email) {
          console.log(`    📧 Email: ${provider.email}`);
        }
      });
    }
  } else {
    console.log('❌ Endpoint failed!');
    console.log('📄 Error details:', endpointResult);
  }

  // Step 4: Check if our frontend integration is working
  console.log('\n🔍 Step 4: Testing frontend integration...');
  
  // Wait a bit longer for any async updates
  await page.waitForTimeout(3000);
  
  // Take a screenshot for manual verification
  await page.screenshot({ path: 'test-oauth-connections-endpoint.png', fullPage: true });
  console.log('📸 Screenshot saved as test-oauth-connections-endpoint.png');

  console.log('\n⏳ Keeping browser open for 30 seconds for manual inspection...');
  await page.waitForTimeout(30000);

  await browser.close();

} catch (error) {
  console.error('❌ Error during OAuth connections endpoint test:', error.message);
  process.exit(1);
}