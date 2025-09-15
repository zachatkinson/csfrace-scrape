const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  try {
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
    await page.screenshot({ path: '/Users/zach/Web Projects/csfrace-scrape/frontend_health_status.png', fullPage: true });
    console.log('Screenshot saved to frontend_health_status.png');
  } catch (error) {
    console.error('Error taking screenshot:', error);
  }

  await browser.close();
})();