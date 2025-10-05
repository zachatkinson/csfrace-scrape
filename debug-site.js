const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    headless: false,
    ignoreHTTPSErrors: true
  });

  const context = await browser.newContext({
    ignoreHTTPSErrors: true
  });

  const page = await context.newPage();

  console.log('🌐 Navigating to https://localhost...');

  try {
    await page.goto('https://localhost', {
      waitUntil: 'networkidle',
      timeout: 30000
    });

    console.log('✅ Page loaded successfully');
    console.log('📄 Page title:', await page.title());

    // Check for sign in button
    console.log('\n🔍 Checking for Sign In button...');
    const signInButton = await page.locator('button:has-text("Sign In")').first();
    const signInVisible = await signInButton.isVisible().catch(() => false);
    console.log(`Sign In button visible: ${signInVisible}`);

    if (signInVisible) {
      console.log('🖱️ Trying to click Sign In button...');
      await signInButton.click();
      await page.waitForTimeout(2000);

      // Check if modal opened
      const modal = await page.locator('[data-testid="auth-modal"], .modal, [role="dialog"]').first();
      const modalVisible = await modal.isVisible().catch(() => false);
      console.log(`Auth modal visible after click: ${modalVisible}`);
    }

    // Check health status
    console.log('\n🏥 Checking health status elements...');
    const healthCards = await page.locator('[data-component="health-card"]');
    const healthCount = await healthCards.count();
    console.log(`Found ${healthCount} health cards`);

    if (healthCount > 0) {
      for (let i = 0; i < Math.min(healthCount, 3); i++) {
        const card = healthCards.nth(i);
        const serviceName = await card.getAttribute('data-service-name').catch(() => 'unknown');
        const isVisible = await card.isVisible().catch(() => false);
        console.log(`  Health card ${i}: ${serviceName} (visible: ${isVisible})`);
      }
    }

    // Check for JavaScript errors
    console.log('\n🐛 Checking for JavaScript errors...');
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.waitForTimeout(3000);

    if (errors.length > 0) {
      console.log('❌ JavaScript errors found:');
      errors.forEach(error => console.log(`  - ${error}`));
    } else {
      console.log('✅ No JavaScript errors detected');
    }

    // Check if astro:page-load event fired
    console.log('\n🚀 Testing Astro page load event...');
    const astroEventFired = await page.evaluate(() => {
      return new Promise((resolve) => {
        let fired = false;
        document.addEventListener('astro:page-load', () => {
          fired = true;
        });
        setTimeout(() => resolve(fired), 1000);
      });
    });
    console.log(`Astro page-load event fired: ${astroEventFired}`);

    console.log('\n⏳ Keeping browser open for 30 seconds for manual inspection...');
    await page.waitForTimeout(30000);

  } catch (error) {
    console.error('❌ Error loading page:', error.message);
  }

  await browser.close();
})();