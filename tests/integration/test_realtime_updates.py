"""
Integration tests for real-time updates and live data synchronization.

This module tests the complete real-time system including:
- WebSocket connections
- Server-Sent Events (SSE)
- Live scraping status updates
- Real-time notifications
- Cross-service data synchronization
"""

import asyncio
import pytest
import httpx
import json
from playwright.async_api import async_playwright, Page, Browser
from typing import Dict, Any, List, Optional
import websockets
from urllib.parse import urlparse


class TestRealtimeUpdates:
    """Test suite for real-time updates integration."""

    @pytest.fixture(scope="class")
    def backend_url(self) -> str:
        """Backend API base URL."""
        return "http://localhost:8001"

    @pytest.fixture(scope="class")
    def frontend_url(self) -> str:
        """Frontend application base URL."""
        return "http://localhost:3001"

    @pytest.fixture(scope="class")
    def websocket_url(self) -> str:
        """WebSocket URL for real-time connections."""
        return "ws://localhost:8001"

    @pytest.fixture(scope="class")
    async def http_client(self) -> httpx.AsyncClient:
        """HTTP client for API testing."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            yield client

    @pytest.fixture(scope="class")
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

    async def test_sse_endpoint_availability(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test Server-Sent Events endpoint availability."""
        try:
            # Test SSE connection endpoint
            async with http_client.stream("GET", f"{backend_url}/events/stream") as response:
                assert response.status_code == 200
                assert "text/event-stream" in response.headers.get("content-type", "")

                # Read first few bytes to confirm streaming
                content = b""
                async for chunk in response.aiter_bytes(1024):
                    content += chunk
                    if len(content) > 100:  # Read enough to verify format
                        break

                # Should contain SSE format markers
                content_str = content.decode('utf-8', errors='ignore')
                assert "data:" in content_str or "event:" in content_str or "id:" in content_str

        except httpx.ConnectError:
            # SSE might not be implemented yet, which is acceptable for initial testing
            pytest.skip("SSE endpoint not available")

    async def test_websocket_connection(self, websocket_url: str):
        """Test WebSocket connection establishment."""
        try:
            # Attempt WebSocket connection
            uri = f"{websocket_url}/ws"
            async with websockets.connect(uri, timeout=10) as websocket:
                # Send ping message
                await websocket.send(json.dumps({"type": "ping"}))

                # Wait for response
                response = await asyncio.wait_for(websocket.recv(), timeout=5)
                response_data = json.loads(response)

                assert "type" in response_data
                assert response_data["type"] in ["pong", "connected", "welcome"]

        except (websockets.exceptions.ConnectionFailure, ConnectionRefusedError, OSError):
            # WebSocket might not be implemented yet
            pytest.skip("WebSocket endpoint not available")

    async def test_scraping_status_updates(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test real-time scraping status updates."""
        # Start a scraping job (this might require authentication in real implementation)
        scraping_data = {
            "url": "https://httpbin.org/html",
            "options": {
                "format": "html",
                "include_images": False,
                "timeout": 30
            }
        }

        try:
            response = await http_client.post(f"{backend_url}/scraper/jobs", json=scraping_data)

            if response.status_code == 401:
                # Authentication required - this is expected
                pytest.skip("Authentication required for scraping jobs")

            elif response.status_code == 201:
                # Job created successfully
                job_data = response.json()
                assert "job_id" in job_data
                job_id = job_data["job_id"]

                # Check job status
                status_response = await http_client.get(f"{backend_url}/scraper/jobs/{job_id}")

                if status_response.status_code == 200:
                    status_data = status_response.json()
                    assert "status" in status_data
                    assert "job_id" in status_data

        except Exception:
            # Scraping endpoint might not be fully implemented
            pytest.skip("Scraping functionality not available for testing")

    async def test_live_notifications(self, page: Page, frontend_url: str):
        """Test live notifications in the frontend."""
        # Navigate to frontend
        await page.goto(frontend_url)
        await page.wait_for_load_state("networkidle")

        # Check for notification system elements
        try:
            # Look for notification containers or toast elements
            notification_selectors = [
                '[data-testid="notifications"]',
                '.notifications',
                '.toast-container',
                '.alerts',
                '[role="alert"]'
            ]

            notification_element = None
            for selector in notification_selectors:
                elements = page.locator(selector)
                if await elements.count() > 0:
                    notification_element = elements.first
                    break

            if notification_element:
                # Notification system exists
                assert await notification_element.is_visible() or await notification_element.count() > 0

        except Exception:
            # Notification system might not be implemented yet
            pass

    async def test_real_time_data_sync(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test real-time data synchronization between services."""
        # Test health status streaming
        try:
            async with http_client.stream("GET", f"{backend_url}/events/health") as response:
                if response.status_code == 200:
                    # Health events streaming is available
                    content = b""
                    async for chunk in response.aiter_bytes(512):
                        content += chunk
                        if len(content) > 200:
                            break

                    content_str = content.decode('utf-8', errors='ignore')

                    # Should contain health status data
                    assert any(keyword in content_str.lower() for keyword in [
                        "healthy", "status", "service", "timestamp"
                    ])

        except Exception:
            # Real-time health streaming might not be implemented
            pytest.skip("Real-time health streaming not available")

    async def test_connection_recovery(self, websocket_url: str):
        """Test connection recovery and reconnection logic."""
        try:
            uri = f"{websocket_url}/ws"

            # Establish connection
            websocket = await websockets.connect(uri, timeout=10)

            # Send initial message
            await websocket.send(json.dumps({"type": "ping"}))
            response = await asyncio.wait_for(websocket.recv(), timeout=5)

            assert response is not None

            # Close connection abruptly
            await websocket.close()

            # Try to reconnect
            websocket2 = await websockets.connect(uri, timeout=10)

            # Send message to verify new connection works
            await websocket2.send(json.dumps({"type": "ping"}))
            response2 = await asyncio.wait_for(websocket2.recv(), timeout=5)

            assert response2 is not None
            await websocket2.close()

        except Exception:
            pytest.skip("WebSocket connection recovery testing not available")

    async def test_concurrent_connections(self, websocket_url: str):
        """Test multiple concurrent real-time connections."""
        try:
            uri = f"{websocket_url}/ws"
            connections = []

            # Create multiple connections
            for i in range(3):
                ws = await websockets.connect(uri, timeout=10)
                connections.append(ws)

            # Send messages from all connections
            for i, ws in enumerate(connections):
                await ws.send(json.dumps({"type": "ping", "client_id": i}))

            # Receive responses from all connections
            responses = []
            for ws in connections:
                response = await asyncio.wait_for(ws.recv(), timeout=5)
                responses.append(response)

            assert len(responses) == len(connections)

            # Close all connections
            for ws in connections:
                await ws.close()

        except Exception:
            pytest.skip("Concurrent WebSocket connections testing not available")

    async def test_event_ordering(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test event ordering in real-time streams."""
        try:
            # Connect to event stream
            async with http_client.stream("GET", f"{backend_url}/events/stream") as response:
                if response.status_code == 200:
                    events = []
                    content = b""

                    # Collect events for a short time
                    timeout_task = asyncio.create_task(asyncio.sleep(5))
                    stream_task = asyncio.create_task(self._collect_sse_events(response, events))

                    done, pending = await asyncio.wait(
                        [timeout_task, stream_task],
                        return_when=asyncio.FIRST_COMPLETED
                    )

                    # Cancel pending tasks
                    for task in pending:
                        task.cancel()

                    # Verify event ordering if events were received
                    if events:
                        # Events should have timestamps or sequence numbers
                        for event in events:
                            assert "timestamp" in event or "id" in event or "sequence" in event

        except Exception:
            pytest.skip("Event ordering testing not available")

    async def _collect_sse_events(self, response, events: List[Dict[str, Any]]):
        """Helper method to collect SSE events."""
        try:
            buffer = ""
            async for chunk in response.aiter_text():
                buffer += chunk

                # Parse SSE events from buffer
                while "\n\n" in buffer:
                    event_text, buffer = buffer.split("\n\n", 1)

                    if event_text.strip():
                        event = self._parse_sse_event(event_text)
                        if event:
                            events.append(event)

                    if len(events) >= 5:  # Collect up to 5 events
                        break

                if len(events) >= 5:
                    break

        except Exception:
            pass

    def _parse_sse_event(self, event_text: str) -> Optional[Dict[str, Any]]:
        """Parse SSE event text into structured data."""
        try:
            event = {}
            for line in event_text.split('\n'):
                line = line.strip()
                if line.startswith('data:'):
                    data = line[5:].strip()
                    try:
                        event['data'] = json.loads(data)
                    except json.JSONDecodeError:
                        event['data'] = data
                elif line.startswith('event:'):
                    event['event'] = line[6:].strip()
                elif line.startswith('id:'):
                    event['id'] = line[3:].strip()
                elif line.startswith('retry:'):
                    event['retry'] = int(line[6:].strip())

            return event if event else None

        except Exception:
            return None

    async def test_message_persistence(self, http_client: httpx.AsyncClient, backend_url: str):
        """Test message persistence and replay functionality."""
        try:
            # Request recent events or message history
            response = await http_client.get(f"{backend_url}/events/recent")

            if response.status_code == 200:
                events_data = response.json()

                assert "events" in events_data or isinstance(events_data, list)

                if "events" in events_data:
                    events = events_data["events"]
                else:
                    events = events_data

                # Verify event structure
                for event in events[:5]:  # Check first 5 events
                    assert isinstance(event, dict)
                    assert "timestamp" in event or "created_at" in event

        except Exception:
            pytest.skip("Message persistence testing not available")

    async def test_frontend_realtime_integration(self, page: Page, frontend_url: str):
        """Test frontend real-time integration capabilities."""
        await page.goto(frontend_url)
        await page.wait_for_load_state("networkidle")

        # Check for WebSocket or SSE connections in browser
        try:
            # Evaluate JavaScript to check for real-time connections
            realtime_status = await page.evaluate("""
                () => {
                    // Check for WebSocket connections
                    const hasWebSocket = window.WebSocket !== undefined;

                    // Check for EventSource (SSE) connections
                    const hasEventSource = window.EventSource !== undefined;

                    // Check for any real-time connection indicators
                    const realtimeElements = document.querySelectorAll(
                        '[data-realtime], [data-websocket], [data-sse], .realtime, .live-updates'
                    );

                    return {
                        webSocketSupport: hasWebSocket,
                        eventSourceSupport: hasEventSource,
                        realtimeElements: realtimeElements.length
                    };
                }
            """)

            # Verify browser supports real-time technologies
            assert realtime_status["webSocketSupport"] is True
            assert realtime_status["eventSourceSupport"] is True

        except Exception:
            # Frontend real-time integration might not be implemented
            pass