const { chromium } = require('playwright');

async function testWebSocketFix() {
  console.log('🔧 Testing WebSocket configuration fix...');

  const browser = await chromium.launch({
    headless: false,
    channel: 'chrome',
  });

  const page = await browser.newPage();

  // Monitor console for WebSocket errors
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('WebSocket') || text.includes('websocket') || text.includes('vite')) {
      console.log(`🖥️  [${msg.type().toUpperCase()}] ${text}`);
    }
  });

  try {
    console.log('📍 Loading https://localhost...');
    await page.goto('https://localhost', {
      waitUntil: 'domcontentloaded'
    });

    console.log('✅ Page loaded - checking for WebSocket errors...');

    // Wait a bit for any WebSocket connection attempts
    await page.waitForTimeout(5000);

    // Check if page is working properly despite WebSocket issues
    const pageInfo = await page.evaluate(() => {
      return {
        title: document.title,
        hasErrors: document.querySelectorAll('[class*="error"]').length > 0,
        viteConnected: !!window.__vite_is_modern_browser,
        websocketErrors: performance.getEntriesByType('navigation').length
      };
    });

    console.log('📊 Page status:');
    console.log(`  Title: ${pageInfo.title}`);
    console.log(`  Has errors: ${pageInfo.hasErrors}`);
    console.log(`  Vite modern browser: ${pageInfo.viteConnected}`);

    console.log('⏳ Waiting to observe WebSocket behavior...');
    await page.waitForTimeout(10000);

  } catch (error) {
    console.error('❌ Test error:', error.message);
  }

  await browser.close();
  console.log('🏁 WebSocket test complete');
}

testWebSocketFix().catch(console.error);