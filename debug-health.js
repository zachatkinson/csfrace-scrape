#!/usr/bin/env node

/**
 * Debug Health Page - Test health cards visibility and SSE functionality
 */

import { chromium } from 'playwright';

const DEBUG_URL = 'https://localhost';
const HEALTH_PAGE_URL = 'https://localhost/health';

console.log('🏥 Testing Health Page Functionality...');

try {
  const browser = await chromium.launch({
    headless: false,
    ignoreHTTPSErrors: true,
  });

  const context = await browser.newContext({
    ignoreHTTPSErrors: true,
  });

  const page = await context.newPage();

  // Monitor console logs
  page.on('console', msg => {
    if (msg.type() !== 'log') return;
    console.log(`🖥️  ${msg.text()}`);
  });

  // Monitor errors
  page.on('pageerror', err => {
    console.log(`❌ JavaScript error: ${err.message}`);
  });

  console.log('🌐 Navigating to health page...');
  await page.goto(HEALTH_PAGE_URL, {
    waitUntil: 'networkidle',
    timeout: 30000
  });

  console.log('✅ Health page loaded successfully');
  console.log(`📄 Page title: ${await page.title()}`);

  // Wait a moment for any dynamic content to load
  await page.waitForTimeout(3000);

  // Check for health cards
  console.log('\n🏥 Checking for health status elements...');
  const healthCards = await page.locator('[data-health-card], .health-card, [class*="health"]').all();
  console.log(`Found ${healthCards.length} health-related elements`);

  // Check for specific health elements
  const backendCard = await page.locator('[data-service="backend"], [data-component*="backend"], [id*="backend"]').count();
  const frontendCard = await page.locator('[data-service="frontend"], [data-component*="frontend"], [id*="frontend"]').count();
  const databaseCard = await page.locator('[data-service="database"], [data-component*="database"], [id*="database"]').count();

  console.log(`Backend cards: ${backendCard}`);
  console.log(`Frontend cards: ${frontendCard}`);
  console.log(`Database cards: ${databaseCard}`);

  // Check for SSE elements
  const sseElements = await page.locator('[data-sse], [data-event-source], [id*="sse"]').count();
  console.log(`SSE elements: ${sseElements}`);

  // Check page content structure
  console.log('\n📋 Page content analysis:');
  const bodyText = await page.locator('body').textContent();
  console.log(`Body text length: ${bodyText?.length || 0} characters`);

  if (bodyText?.includes('health')) {
    console.log('✅ Page contains "health" text');
  } else {
    console.log('❌ Page does not contain "health" text');
  }

  // Look for any loading states
  const loadingElements = await page.locator('[data-loading], [class*="loading"], .animate-spin').count();
  console.log(`Loading elements: ${loadingElements}`);

  // Check for error messages
  const errorElements = await page.locator('[data-error], [class*="error"], .text-red').count();
  console.log(`Error elements: ${errorElements}`);

  // Take a screenshot for debugging
  await page.screenshot({ path: 'debug-health.png', fullPage: true });
  console.log('📸 Screenshot saved as debug-health.png');

  console.log('\n⏳ Keeping browser open for 30 seconds for manual inspection...');
  await page.waitForTimeout(30000);

  await browser.close();

} catch (error) {
  console.error('❌ Error during health page test:', error.message);
  process.exit(1);
}