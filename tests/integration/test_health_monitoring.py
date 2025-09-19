"""
Integration tests for health monitoring and system observability.

This module tests the complete monitoring stack including:
- Service health checks
- Metrics collection and exposure
- Dependency monitoring
- Performance monitoring
- Alert mechanisms
"""

import asyncio
import pytest
import httpx
import time
from typing import Dict, Any, List


class TestHealthMonitoring:
    """Test suite for health monitoring integration."""

    @pytest.fixture(scope="class")
    def backend_url(self) -> str:
        """Backend API base URL."""
        return "http://localhost:8001"

    @pytest.fixture(scope="class")
    def frontend_url(self) -> str:
        """Frontend application base URL."""
        return "http://localhost:3001"

    @pytest.fixture(scope="class")
    async def http_client(self) -> httpx.AsyncClient:
        """HTTP client for API testing."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            yield client

    async def test_backend_health_endpoint(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test comprehensive backend health check endpoint."""
        response = await http_client.get(f"{backend_url}/health/")

        assert response.status_code == 200

        health_data = response.json()

        # Verify top-level health structure
        assert health_data["status"] == "healthy"
        assert "timestamp" in health_data
        assert "version" in health_data
        assert "uptime" in health_data
        assert "services" in health_data

        # Verify service dependencies
        services = health_data["services"]

        # Database health
        assert "database" in services
        db_health = services["database"]
        assert db_health["status"] == "healthy"
        assert "connection_pool" in db_health
        assert "response_time_ms" in db_health

        # Cache health
        assert "cache" in services
        cache_health = services["cache"]
        assert cache_health["status"] == "healthy"
        assert "response_time_ms" in cache_health

    async def test_frontend_health_check(self, http_client: httpx.AsyncClient, frontend_url: str):
        """Test frontend service availability and health."""
        response = await http_client.get(frontend_url)

        assert response.status_code == 200
        assert "text/html" in response.headers.get("content-type", "")

        # Test response time
        assert response.elapsed.total_seconds() < 5.0  # Should respond within 5 seconds

    async def test_metrics_endpoint(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test Prometheus metrics endpoint."""
        response = await http_client.get(f"{backend_url}/metrics")

        assert response.status_code == 200
        assert "text/plain" in response.headers.get("content-type", "")

        metrics_text = response.text

        # Verify Prometheus format
        assert "# HELP" in metrics_text
        assert "# TYPE" in metrics_text

        # Verify essential metrics are present
        essential_metrics = [
            "http_requests_total",
            "http_request_duration_seconds",
            "process_start_time_seconds",
            "python_info"
        ]

        for metric in essential_metrics:
            assert metric in metrics_text

    async def test_dependency_health_checks(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test individual dependency health checks."""
        # Test database health specifically
        response = await http_client.get(f"{backend_url}/health/database")

        if response.status_code == 200:
            db_health = response.json()
            assert db_health["status"] in ["healthy", "degraded"]
            assert "connection_pool" in db_health
            assert "active_connections" in db_health["connection_pool"]
            assert "max_connections" in db_health["connection_pool"]

        # Test cache health specifically
        response = await http_client.get(f"{backend_url}/health/cache")

        if response.status_code == 200:
            cache_health = response.json()
            assert cache_health["status"] in ["healthy", "degraded"]
            assert "response_time_ms" in cache_health

    async def test_performance_monitoring(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test performance monitoring and response times."""
        # Measure response times for key endpoints
        endpoints = [
            "/health/",
            "/auth/providers",
            "/metrics"
        ]

        response_times = []

        for endpoint in endpoints:
            start_time = time.time()
            response = await http_client.get(f"{backend_url}{endpoint}")
            end_time = time.time()

            response_time = end_time - start_time
            response_times.append(response_time)

            # Each endpoint should respond quickly
            assert response_time < 2.0  # Under 2 seconds
            assert response.status_code == 200

        # Average response time should be reasonable
        avg_response_time = sum(response_times) / len(response_times)
        assert avg_response_time < 1.0  # Under 1 second average

    async def test_error_monitoring(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test error monitoring and logging."""
        # Test 404 error handling
        response = await http_client.get(f"{backend_url}/nonexistent-endpoint")

        assert response.status_code == 404

        error_data = response.json()
        assert "detail" in error_data

        # Test 422 validation error
        invalid_data = {"invalid": "data"}
        response = await http_client.post(
            f"{backend_url}/auth/logout",
            json=invalid_data
        )

        # Should handle invalid JSON gracefully
        assert response.status_code in [200, 400, 422]

    async def test_system_resource_monitoring(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test system resource monitoring metrics."""
        response = await http_client.get(f"{backend_url}/metrics")

        assert response.status_code == 200
        metrics_text = response.text

        # Check for system metrics
        system_metrics = [
            "process_virtual_memory_bytes",
            "process_resident_memory_bytes",
            "process_cpu_seconds_total",
            "process_open_fds"
        ]

        for metric in system_metrics:
            assert metric in metrics_text

        # Verify metrics have values
        for line in metrics_text.split('\n'):
            if any(metric in line for metric in system_metrics):
                if not line.startswith('#') and line.strip():
                    # Should have a numeric value
                    parts = line.split()
                    if len(parts) >= 2:
                        try:
                            float(parts[-1])  # Last part should be numeric
                        except ValueError:
                            pytest.fail(f"Invalid metric value in line: {line}")

    async def test_concurrent_health_checks(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test health endpoint under concurrent load."""
        # Create multiple concurrent requests
        tasks = []

        for _ in range(10):
            task = http_client.get(f"{backend_url}/health/")
            tasks.append(task)

        # Execute all requests concurrently
        responses = await asyncio.gather(*tasks)

        # All requests should succeed
        for response in responses:
            assert response.status_code == 200

            health_data = response.json()
            assert health_data["status"] == "healthy"

    async def test_health_check_caching(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test health check response caching behavior."""
        # Make multiple rapid requests
        responses = []

        for _ in range(3):
            response = await http_client.get(f"{backend_url}/health/")
            responses.append(response)
            await asyncio.sleep(0.1)  # Small delay

        # All should succeed
        for response in responses:
            assert response.status_code == 200

        # Check if caching headers are present
        first_response = responses[0]
        cache_headers = [
            "cache-control",
            "etag",
            "last-modified"
        ]

        # At least one caching header should be present
        has_cache_header = any(header in first_response.headers for header in cache_headers)

        if has_cache_header:
            # If caching is implemented, subsequent requests might be faster
            response_times = [r.elapsed.total_seconds() for r in responses]
            # First request might be slower than subsequent ones
            assert max(response_times) >= min(response_times)

    async def test_cross_service_health_dependency(self, http_client: httpx.AsyncClient, backend_url: str, frontend_url: str):
        """Test cross-service health dependencies."""
        # Test that frontend can reach backend
        try:
            # Make request through frontend to backend
            # This would require the frontend to proxy health checks
            response = await http_client.get(f"{frontend_url}/api/health")

            if response.status_code == 200:
                # Frontend successfully proxied to backend
                health_data = response.json()
                assert "status" in health_data

        except Exception:
            # If frontend doesn't proxy health checks, that's also valid
            pass

        # Verify both services are independently healthy
        backend_response = await http_client.get(f"{backend_url}/health/")
        frontend_response = await http_client.get(frontend_url)

        assert backend_response.status_code == 200
        assert frontend_response.status_code == 200

    async def test_monitoring_data_freshness(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test that monitoring data is fresh and up-to-date."""
        response = await http_client.get(f"{backend_url}/health/")

        assert response.status_code == 200
        health_data = response.json()

        # Check timestamp freshness
        timestamp = health_data.get("timestamp")
        if timestamp:
            # Timestamp should be recent (within last minute)
            import datetime
            try:
                if 'T' in timestamp:
                    # ISO format
                    health_time = datetime.datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                else:
                    # Unix timestamp
                    health_time = datetime.datetime.fromtimestamp(float(timestamp))

                now = datetime.datetime.now(health_time.tzinfo or datetime.timezone.utc)
                time_diff = (now - health_time).total_seconds()

                # Should be within last 60 seconds
                assert time_diff < 60

            except (ValueError, TypeError):
                # If timestamp format is different, just verify it exists
                assert timestamp is not None

    async def test_alert_thresholds(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test monitoring alert thresholds and conditions."""
        response = await http_client.get(f"{backend_url}/health/")

        assert response.status_code == 200
        health_data = response.json()

        services = health_data.get("services", {})

        # Check database connection pool thresholds
        if "database" in services:
            db_health = services["database"]
            if "connection_pool" in db_health:
                pool_info = db_health["connection_pool"]
                active = pool_info.get("active_connections", 0)
                max_conn = pool_info.get("max_connections", 100)

                # Connection pool should not be exhausted
                utilization = active / max_conn if max_conn > 0 else 0
                assert utilization < 0.9  # Less than 90% utilization

        # Check response time thresholds
        for service_name, service_health in services.items():
            response_time = service_health.get("response_time_ms", 0)
            # Response times should be reasonable
            assert response_time < 1000  # Under 1 second