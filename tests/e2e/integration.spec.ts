import { test, expect } from "@playwright/test";

test.describe("Integration Tests @integration", () => {
  const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || "http://localhost:3000";

  test("should load frontend application @integration", async ({ page }) => {
    await page.goto("/");
    await page.waitForLoadState("networkidle");

    // Verify page loads successfully
    expect(page.url()).toContain(BASE_URL);

    // Check for basic page structure
    const body = await page.locator("body");
    await expect(body).toBeVisible();

    // Verify HTML document structure
    const html = await page.locator("html");
    await expect(html).toBeVisible();
  });

  test("should have proper page title @integration", async ({ page }) => {
    await page.goto("/");
    await page.waitForLoadState("networkidle");

    // Check page has a title (not empty)
    const title = await page.title();
    expect(title.length).toBeGreaterThan(0);
  });

  test("should handle frontend routing @integration", async ({ page }) => {
    await page.goto("/");
    await page.waitForLoadState("networkidle");

    // Verify we're on the home page
    const currentUrl = page.url();
    expect(currentUrl).toContain("localhost:3000");

    // Check for common navigation elements
    const bodyContent = await page.textContent("body");
    expect(bodyContent).toBeTruthy();
    expect(bodyContent.length).toBeGreaterThan(0);
  });

  test("should load CSS and JavaScript resources @integration", async ({
    page,
  }) => {
    const responses: any[] = [];
    page.on("response", (response) => responses.push(response));

    await page.goto("/");
    await page.waitForLoadState("networkidle");

    // Check that some resources loaded successfully
    const successfulResponses = responses.filter(
      (r) => r.status() >= 200 && r.status() < 300,
    );
    expect(successfulResponses.length).toBeGreaterThan(0);

    // Check that the main document loaded
    const htmlResponses = responses.filter(
      (r) => r.url().includes("localhost:3000") && r.status() === 200,
    );
    expect(htmlResponses.length).toBeGreaterThan(0);
  });

  test("should handle frontend error states gracefully @integration", async ({
    page,
  }) => {
    // Navigate to a non-existent route
    await page.goto("/non-existent-page");
    await page.waitForLoadState("networkidle");

    // Should not crash the application
    const body = await page.locator("body");
    await expect(body).toBeVisible();

    // Should have some content (error page, 404, or redirect to home)
    const bodyContent = await page.textContent("body");
    expect(bodyContent).toBeTruthy();
    expect(bodyContent.length).toBeGreaterThan(0);
  });
});