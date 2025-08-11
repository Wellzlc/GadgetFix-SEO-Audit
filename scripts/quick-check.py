#!/usr/bin/env python3
import sys
import json
import requests
from datetime import datetime

def basic_seo_check(url):
    """Basic SEO health check"""
    print(f"🔍 Running basic SEO check for {url}")
    
    try:
        # Basic URL check
        response = requests.get(url, timeout=10)
        
        # Create basic report
        report = {
            "url": url,
            "timestamp": datetime.now().isoformat(),
            "status_code": response.status_code,
            "response_time": response.elapsed.total_seconds(),
            "content_length": len(response.content),
            "has_title": "<title>" in response.text.lower(),
            "has_meta_description": 'name="description"' in response.text.lower(),
        }
        
        # Save results
        with open("quick-results.json", "w") as f:
            json.dump(report, f, indent=2)
        
        print(f"✅ Check completed! Status: {response.status_code}")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    import os
    url = os.getenv("WEBSITE_URL", sys.argv[1] if len(sys.argv) > 1 else "https://example.com")
    success = basic_seo_check(url)
    sys.exit(0 if success else 1)
