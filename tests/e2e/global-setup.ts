import { chromium, FullConfig } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  console.log('🚀 Starting global E2E test setup...');

  const baseURL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000';
  const apiURL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:8000';
  const testEnvironment = process.env.TEST_ENVIRONMENT || 'local';

  console.log(`📍 Environment: ${testEnvironment}`);
  console.log(`🌐 Base URL: ${baseURL}`);
  console.log(`🔗 API URL: ${apiURL}`);

  // For local testing, verify services are running
  if (testEnvironment === 'local') {
    console.log('🔍 Verifying local services...');

    try {
      // Check if services are reachable
      const browser = await chromium.launch();
      const page = await browser.newPage();

      // Test backend health
      try {
        const apiResponse = await page.request.get(`${apiURL}/health/`);
        if (apiResponse.status() === 200) {
          console.log('✅ Backend service is healthy');
        } else {
          console.warn(`⚠️ Backend service returned status: ${apiResponse.status()}`);
        }
      } catch (error) {
        console.error('❌ Backend service is not reachable:', error);
        throw new Error('Backend service is required for E2E tests');
      }

      // Test frontend accessibility
      try {
        const frontendResponse = await page.request.get(baseURL);
        if (frontendResponse.status() === 200) {
          console.log('✅ Frontend service is accessible');
        } else {
          console.warn(`⚠️ Frontend service returned status: ${frontendResponse.status()}`);
        }
      } catch (error) {
        console.error('❌ Frontend service is not reachable:', error);
        throw new Error('Frontend service is required for E2E tests');
      }

      await browser.close();
    } catch (error) {
      console.error('❌ Service verification failed:', error);
      throw error;
    }
  }

  // Create test data directory
  const fs = require('fs');
  const path = require('path');

  const testDataDir = path.join(process.cwd(), 'test-results');
  if (!fs.existsSync(testDataDir)) {
    fs.mkdirSync(testDataDir, { recursive: true });
    console.log('📁 Created test results directory');
  }

  // Setup test environment variables
  process.env.E2E_TEST_SESSION_ID = Date.now().toString();
  console.log(`🔖 Test session ID: ${process.env.E2E_TEST_SESSION_ID}`);

  console.log('✅ Global E2E setup completed successfully');
}

export default globalSetup;