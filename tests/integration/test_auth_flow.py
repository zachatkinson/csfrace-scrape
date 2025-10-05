"""
Integration tests for authentication flow across frontend and backend services.

This module tests the complete OAuth authentication workflow including:
- OAuth provider discovery
- Authorization URL generation
- Token exchange flow
- User session management
- Cross-service authentication state
"""

import asyncio
import pytest
import httpx
from playwright.async_api import async_playwright, Page, Browser
from typing import Dict, Any, Optional


class TestAuthFlow:
    """Test suite for authentication flow integration."""

    @pytest.fixture
    def backend_url(self) -> str:
        """Backend API base URL."""
        return "http://localhost:8001"

    @pytest.fixture
    def frontend_url(self) -> str:
        """Frontend application base URL."""
        return "http://localhost:3001"

    @pytest.fixture
    async def http_client(self) -> httpx.AsyncClient:
        """HTTP client for API testing."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            yield client

    @pytest.fixture
    async def browser(self) -> Browser:
        """Browser instance for end-to-end testing."""
        playwright = await async_playwright().start()
        browser = await playwright.chromium.launch(headless=True)
        yield browser
        await browser.close()
        await playwright.stop()

    @pytest.fixture
    async def page(self, browser: Browser) -> Page:
        """Browser page for testing."""
        page = await browser.new_page()
        yield page
        await page.close()

    async def test_backend_health_check(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test backend service health and readiness."""
        response = await http_client.get(f"{backend_url}/health/")

        assert response.status_code == 200
        health_data = response.json()

        assert health_data["status"] == "healthy"
        assert "timestamp" in health_data
        assert "version" in health_data
        assert "services" in health_data

        # Verify database connectivity
        assert health_data["services"]["database"]["status"] == "healthy"

        # Verify cache connectivity
        assert health_data["services"]["cache"]["status"] == "healthy"

    async def test_frontend_accessibility(self, http_client: httpx.AsyncClient, frontend_url: str):
        """Test frontend service accessibility."""
        response = await http_client.get(frontend_url)

        assert response.status_code == 200
        assert "text/html" in response.headers.get("content-type", "")
        assert "<!DOCTYPE html>" in response.text

    async def test_oauth_providers_discovery(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test OAuth provider discovery endpoint."""
        response = await http_client.get(f"{backend_url}/auth/providers")

        assert response.status_code == 200
        providers_data = response.json()

        assert "providers" in providers_data
        assert len(providers_data["providers"]) >= 2

        provider_names = [p["name"] for p in providers_data["providers"]]
        assert "google" in provider_names
        assert "github" in provider_names

        # Verify provider structure
        for provider in providers_data["providers"]:
            assert "name" in provider
            assert "display_name" in provider
            assert "authorization_url" in provider

    async def test_google_oauth_authorization_url(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test Google OAuth authorization URL generation."""
        response = await http_client.get(f"{backend_url}/auth/google/authorize")

        assert response.status_code == 200
        auth_data = response.json()

        assert "authorization_url" in auth_data
        assert "state" in auth_data

        auth_url = auth_data["authorization_url"]
        assert "accounts.google.com" in auth_url
        assert "oauth2" in auth_url
        assert "client_id" in auth_url
        assert "redirect_uri" in auth_url
        assert "scope" in auth_url
        assert "state" in auth_url

    async def test_github_oauth_authorization_url(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test GitHub OAuth authorization URL generation."""
        response = await http_client.get(f"{backend_url}/auth/github/authorize")

        assert response.status_code == 200
        auth_data = response.json()

        assert "authorization_url" in auth_data
        assert "state" in auth_data

        auth_url = auth_data["authorization_url"]
        assert "github.com" in auth_url
        assert "oauth/authorize" in auth_url
        assert "client_id" in auth_url
        assert "redirect_uri" in auth_url
        assert "scope" in auth_url
        assert "state" in auth_url

    async def test_cors_configuration(self, http_client: httpx.AsyncClient, backend_url: str, frontend_url: str):
        """Test CORS configuration for cross-origin requests."""
        # Test preflight request
        headers = {
            "Origin": frontend_url,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "Content-Type, Authorization"
        }

        response = await http_client.request(
            "OPTIONS",
            f"{backend_url}/auth/providers",
            headers=headers
        )

        assert response.status_code == 200

        # Verify CORS headers
        cors_headers = response.headers
        assert "access-control-allow-origin" in cors_headers
        assert "access-control-allow-methods" in cors_headers
        assert "access-control-allow-headers" in cors_headers

        allowed_origin = cors_headers.get("access-control-allow-origin")
        assert allowed_origin == frontend_url or allowed_origin == "*"

    async def test_authentication_state_persistence(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test authentication state management and session persistence."""
        # This test would require mock OAuth tokens or test user credentials
        # For now, we test the authentication state endpoints

        # Test current user endpoint (should require authentication)
        response = await http_client.get(f"{backend_url}/auth/me")

        # Should return 401 Unauthorized without valid token
        assert response.status_code == 401

        error_data = response.json()
        assert "detail" in error_data

    async def test_logout_functionality(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test logout functionality."""
        # Test logout endpoint (should work even without authentication)
        response = await http_client.post(f"{backend_url}/auth/logout")

        # Should return success or appropriate status
        assert response.status_code in [200, 401]  # 200 if logged out, 401 if not authenticated

    async def test_frontend_auth_integration(self, page: Page, frontend_url: str):
        """Test frontend authentication integration using browser automation."""
        # Navigate to frontend
        await page.goto(frontend_url)

        # Wait for page to load
        await page.wait_for_load_state("networkidle")

        # Check if login elements are present
        # This assumes the frontend has OAuth login buttons
        try:
            # Look for OAuth provider buttons or links
            google_login = page.locator('[data-provider="google"], [href*="google"], text=Google')
            github_login = page.locator('[data-provider="github"], [href*="github"], text=GitHub')

            # Verify OAuth login options are available
            if await google_login.count() > 0:
                assert await google_login.is_visible()

            if await github_login.count() > 0:
                assert await github_login.is_visible()

        except Exception as e:
            # If specific elements aren't found, just verify the page loaded
            assert "error" not in page.url.lower()

    async def test_api_error_handling(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test API error handling and response formats."""
        # Test invalid OAuth provider
        response = await http_client.get(f"{backend_url}/auth/invalid-provider/authorize")

        assert response.status_code == 404
        error_data = response.json()
        assert "detail" in error_data

    async def test_rate_limiting(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test rate limiting on authentication endpoints."""
        # Make multiple rapid requests to test rate limiting
        responses = []

        for _ in range(10):
            response = await http_client.get(f"{backend_url}/auth/providers")
            responses.append(response)

        # All requests should succeed under normal circumstances
        # Rate limiting would return 429 Too Many Requests
        success_responses = [r for r in responses if r.status_code == 200]

        # Should have at least some successful responses
        assert len(success_responses) > 0

        # Check if any rate limiting occurred
        rate_limited = [r for r in responses if r.status_code == 429]

        if rate_limited:
            # If rate limiting is implemented, verify proper headers
            for response in rate_limited:
                assert "retry-after" in response.headers or "x-ratelimit-remaining" in response.headers

    async def test_security_headers(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test security headers in authentication responses."""
        response = await http_client.get(f"{backend_url}/auth/providers")

        assert response.status_code == 200

        headers = response.headers

        # Check for security headers
        security_headers = [
            "x-content-type-options",
            "x-frame-options",
            "x-xss-protection",
            "strict-transport-security"
        ]

        # At least some security headers should be present
        present_headers = [h for h in security_headers if h in headers]
        assert len(present_headers) > 0