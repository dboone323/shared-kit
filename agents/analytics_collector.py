#!/usr/bin/env python3
"""
Analytics Collector Agent
Collects and aggregates analytics data.
"""

try:
    from .utils import safe_run, user_log
except ImportError:
    from utils import safe_run, user_log


def collect_analytics():
    """Collect analytics from various sources."""
    user_log("Collecting analytics data...")
    
    try:
        result = safe_run(["git", "rev-parse", "HEAD"], capture_output=True)
        user_log("Analytics collected", level="info", commit=result.stdout.strip()[:8])
        return result.stdout
    except Exception as e:
        user_log(f"Analytics collection failed: {e}", level="error")
        return None


if __name__ == "__main__":
    collect_analytics()
