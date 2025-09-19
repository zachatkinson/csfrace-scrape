import { FullConfig } from '@playwright/test';

async function globalTeardown(config: FullConfig) {
  console.log('🧹 Starting global E2E test teardown...');

  const testEnvironment = process.env.TEST_ENVIRONMENT || 'local';
  const sessionId = process.env.E2E_TEST_SESSION_ID;

  console.log(`📍 Environment: ${testEnvironment}`);
  console.log(`🔖 Test session ID: ${sessionId}`);

  // Generate test summary
  const fs = require('fs');
  const path = require('path');

  try {
    const testResultsDir = path.join(process.cwd(), 'test-results');
    const summaryPath = path.join(testResultsDir, 'test-summary.json');

    const summary = {
      sessionId,
      environment: testEnvironment,
      completedAt: new Date().toISOString(),
      baseUrl: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000',
      apiUrl: process.env.PLAYWRIGHT_API_URL || 'http://localhost:8000'
    };

    fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));
    console.log('📊 Test summary generated');
  } catch (error) {
    console.warn('⚠️ Could not generate test summary:', error);
  }

  // Cleanup temporary files
  try {
    const tempFiles = [
      'test-results/temp-*.json',
      'test-results/temp-*.txt'
    ];

    for (const pattern of tempFiles) {
      const glob = require('glob');
      const files = glob.sync(pattern);
      files.forEach((file: string) => {
        try {
          fs.unlinkSync(file);
        } catch (err) {
          // Ignore cleanup errors
        }
      });
    }

    console.log('🗑️ Temporary files cleaned up');
  } catch (error) {
    console.warn('⚠️ Could not clean up temporary files:', error);
  }

  // For local environment, optionally stop services
  if (testEnvironment === 'local' && process.env.E2E_CLEANUP_SERVICES === 'true') {
    console.log('🛑 Stopping local test services...');

    try {
      const { execSync } = require('child_process');
      execSync('docker compose -f docker-compose.test.yml down -v', {
        stdio: 'pipe',
        cwd: process.cwd()
      });
      console.log('✅ Local test services stopped');
    } catch (error) {
      console.warn('⚠️ Could not stop local services:', error);
    }
  }

  console.log('✅ Global E2E teardown completed');
}

export default globalTeardown;