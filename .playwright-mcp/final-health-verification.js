const { chromium } = require('playwright');

async function finalHealthVerification() {
    console.log('🔍 Starting Final Health Monitoring Verification Test');
    console.log('=' .repeat(60));

    const browser = await chromium.launch({
        headless: false,
        slowMo: 1000 // Slow down actions for better observation
    });

    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 }
    });

    const page = await context.newPage();

    // Set up console monitoring
    const consoleLogs = [];
    const errorLogs = [];

    page.on('console', msg => {
        const logEntry = {
            type: msg.type(),
            text: msg.text(),
            timestamp: new Date().toISOString()
        };
        consoleLogs.push(logEntry);

        if (msg.type() === 'error') {
            errorLogs.push(logEntry);
        }

        // Log important messages immediately
        if (msg.text().includes('SSE') ||
            msg.text().includes('health') ||
            msg.text().includes('Connected') ||
            msg.text().includes('Store') ||
            msg.text().includes('status')) {
            console.log(`📟 [${msg.type().toUpperCase()}] ${msg.text()}`);
        }
    });

    // Set up network monitoring for SSE connections
    const networkRequests = [];
    page.on('request', request => {
        if (request.url().includes('/health') || request.url().includes('/sse')) {
            networkRequests.push({
                url: request.url(),
                method: request.method(),
                timestamp: new Date().toISOString()
            });
            console.log(`🌐 Network Request: ${request.method()} ${request.url()}`);
        }
    });

    page.on('response', response => {
        if (response.url().includes('/health') || response.url().includes('/sse')) {
            console.log(`🌐 Network Response: ${response.status()} ${response.url()}`);
        }
    });

    try {
        console.log('🚀 Navigating to http://localhost:3000');
        await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });

        console.log('⏳ Waiting 5 seconds for page and health system to fully load...');
        await page.waitForTimeout(5000);

        // Take initial screenshot
        console.log('📸 Taking initial screenshot...');
        await page.screenshot({
            path: '/Users/zach/Web Projects/csfrace-scrape/.playwright-mcp/final-health-status-verification.png',
            fullPage: true
        });

        // Check for health status indicators
        console.log('🔍 Analyzing health status indicators...');

        // Look for health status containers
        const healthStatusContainers = await page.locator('[data-testid*="health"], [class*="health"], .status-indicator, .service-status').all();
        console.log(`Found ${healthStatusContainers.length} potential health status elements`);

        // Check footer for status lights
        const footer = await page.locator('footer').first();
        if (await footer.isVisible()) {
            console.log('👀 Footer found, checking for status lights...');

            // Look for common status indicator patterns
            const statusLights = await footer.locator('div[class*="status"], span[class*="status"], .indicator, [class*="light"], [class*="dot"]').all();
            console.log(`Found ${statusLights.length} potential status lights in footer`);

            for (let i = 0; i < statusLights.length; i++) {
                const light = statusLights[i];
                const classes = await light.getAttribute('class') || '';
                const style = await light.getAttribute('style') || '';
                const text = await light.textContent() || '';

                console.log(`Status Light ${i + 1}:`);
                console.log(`  Classes: ${classes}`);
                console.log(`  Style: ${style}`);
                console.log(`  Text: ${text.trim()}`);

                // Check for green colors
                if (classes.includes('green') || style.includes('green') ||
                    classes.includes('success') || classes.includes('healthy')) {
                    console.log(`  ✅ Status Light ${i + 1} appears to be GREEN/HEALTHY`);
                } else if (classes.includes('yellow') || style.includes('yellow') ||
                          classes.includes('warning') || classes.includes('amber')) {
                    console.log(`  ⚠️  Status Light ${i + 1} appears to be YELLOW/WARNING`);
                } else if (classes.includes('red') || style.includes('red') ||
                          classes.includes('error') || classes.includes('danger')) {
                    console.log(`  ❌ Status Light ${i + 1} appears to be RED/ERROR`);
                } else {
                    console.log(`  ❓ Status Light ${i + 1} color unclear`);
                }
            }
        }

        // Check for "Last Updated" timestamp
        console.log('🕐 Checking for "Last Updated" timestamps...');
        const lastUpdatedElements = await page.getByText(/last updated|updated at|timestamp/i).all();
        for (let i = 0; i < lastUpdatedElements.length; i++) {
            const element = lastUpdatedElements[i];
            const text = await element.textContent() || '';
            console.log(`Last Updated ${i + 1}: ${text.trim()}`);

            if (text.toLowerCase().includes('never')) {
                console.log(`  ⚠️  Still showing "Never" - may indicate no updates received`);
            } else if (text.match(/\d{1,2}:\d{2}|\d{4}-\d{2}-\d{2}/)) {
                console.log(`  ✅ Shows actual timestamp - updates are working`);
            }
        }

        // Monitor console for 10 seconds
        console.log('👂 Monitoring browser console for 10 seconds to capture real-time updates...');
        const startTime = Date.now();
        let updateCount = 0;

        while (Date.now() - startTime < 10000) {
            await page.waitForTimeout(1000);

            // Check for new console logs about health updates
            const recentLogs = consoleLogs.filter(log =>
                new Date(log.timestamp).getTime() > startTime &&
                (log.text.includes('health') || log.text.includes('SSE') || log.text.includes('Store'))
            );

            if (recentLogs.length > updateCount) {
                const newLogs = recentLogs.slice(updateCount);
                newLogs.forEach(log => {
                    console.log(`📟 Real-time: [${log.type.toUpperCase()}] ${log.text}`);
                });
                updateCount = recentLogs.length;
            }
        }

        // Execute JavaScript to check Nano Store state
        console.log('🏪 Checking Nano Store state...');
        const storeState = await page.evaluate(() => {
            try {
                // Try to access the health store if it's available globally
                if (window.healthStore) {
                    return {
                        available: true,
                        state: window.healthStore.get ? window.healthStore.get() : 'No get method'
                    };
                }

                // Alternative: check for any store-related globals
                const storeKeys = Object.keys(window).filter(key =>
                    key.includes('store') || key.includes('Store') || key.includes('health')
                );

                return {
                    available: false,
                    storeKeys: storeKeys,
                    message: 'Health store not found in global scope'
                };
            } catch (error) {
                return {
                    available: false,
                    error: error.message
                };
            }
        });

        console.log('Nano Store State:', JSON.stringify(storeState, null, 2));

        // Check for SSE connections in DevTools
        console.log('🔌 Checking for active SSE connections...');
        const sseInfo = await page.evaluate(() => {
            // Check for EventSource instances
            const eventSources = [];

            // Try to find EventSource references
            if (window.EventSource) {
                // Can't directly enumerate EventSource instances, but we can check if the constructor exists
                return {
                    eventSourceAvailable: true,
                    message: 'EventSource constructor is available'
                };
            }

            return {
                eventSourceAvailable: false,
                message: 'EventSource not available'
            };
        });

        console.log('SSE Connection Info:', JSON.stringify(sseInfo, null, 2));

        // Final analysis
        console.log('');
        console.log('🎯 FINAL VERIFICATION RESULTS');
        console.log('=' .repeat(60));

        // Check if errors occurred
        if (errorLogs.length > 0) {
            console.log('❌ JavaScript Errors Detected:');
            errorLogs.forEach((error, index) => {
                console.log(`  ${index + 1}. ${error.text}`);
            });
        } else {
            console.log('✅ No JavaScript errors detected');
        }

        // Check for health-related network activity
        const healthRequests = networkRequests.filter(req =>
            req.url.includes('/health') || req.url.includes('/sse')
        );

        if (healthRequests.length > 0) {
            console.log('✅ Health-related network activity detected:');
            healthRequests.forEach((req, index) => {
                console.log(`  ${index + 1}. ${req.method} ${req.url}`);
            });
        } else {
            console.log('⚠️  No health-related network activity detected');
        }

        // Check for health-related console logs
        const healthLogs = consoleLogs.filter(log =>
            log.text.toLowerCase().includes('health') ||
            log.text.toLowerCase().includes('sse') ||
            log.text.toLowerCase().includes('connected') ||
            log.text.toLowerCase().includes('store')
        );

        if (healthLogs.length > 0) {
            console.log('✅ Health system console activity detected:');
            healthLogs.slice(-5).forEach((log, index) => {
                console.log(`  [${log.type.toUpperCase()}] ${log.text}`);
            });
        } else {
            console.log('⚠️  No health system console activity detected');
        }

        console.log('');
        console.log('📄 Full console log summary:');
        console.log(`Total console messages: ${consoleLogs.length}`);
        console.log(`Error messages: ${errorLogs.length}`);
        console.log(`Health-related messages: ${healthLogs.length}`);
        console.log(`Network requests monitored: ${networkRequests.length}`);

    } catch (error) {
        console.error('❌ Test failed with error:', error.message);
    } finally {
        console.log('🏁 Closing browser...');
        await browser.close();
    }
}

// Run the verification
finalHealthVerification().catch(console.error);