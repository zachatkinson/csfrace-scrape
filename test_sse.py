#!/usr/bin/env python3
"""Quick script to test SSE endpoint and capture initial events."""

import requests
import time
import sys

def test_sse_endpoint():
    """Test the SSE health stream endpoint."""
    try:
        print("Connecting to SSE endpoint...")
        response = requests.get('http://localhost:8000/health/stream', stream=True, timeout=10)
        
        if response.status_code == 200:
            print(f"✅ Connected! Status: {response.status_code}")
            print("📡 Receiving SSE events:")
            print("-" * 50)
            
            # Read first few events
            event_count = 0
            start_time = time.time()
            
            for line in response.iter_lines():
                if line:
                    decoded_line = line.decode('utf-8')
                    print(decoded_line)
                    
                    if decoded_line.startswith('data:'):
                        event_count += 1
                        
                    # Stop after 5 events or 10 seconds
                    if event_count >= 5 or (time.time() - start_time) > 10:
                        break
                        
            print("-" * 50)
            print(f"✅ Captured {event_count} events successfully!")
            return True
            
        else:
            print(f"❌ Connection failed: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_sse_endpoint()
    sys.exit(0 if success else 1)