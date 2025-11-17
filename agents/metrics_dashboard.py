#!/usr/bin/env python3
"""
Metrics Dashboard Agent
Monitors and displays workflow metrics and statistics.
"""

try:
    from .utils import safe_run, user_log
except ImportError:
    from utils import safe_run, user_log


def collect_metrics():
    """Collect metrics from various sources."""
    user_log("Starting metrics collection...")
    
    try:
        # Example: Use safe_run instead of subprocess.run
        result = safe_run(
            ["git", "log", "--oneline", "-n", "10"],
            capture_output=True
        )
        
        user_log("Metrics collected successfully", level="info", count=10)
        return result.stdout
    except Exception as e:
        user_log(f"Failed to collect metrics: {e}", level="error")
        return None


def display_dashboard():
    """Display the metrics dashboard."""
    user_log("Displaying metrics dashboard...")
    metrics = collect_metrics()
    
    if metrics:
        user_log("Dashboard ready", level="info")
    else:
        user_log("Dashboard unavailable", level="warning")


if __name__ == "__main__":
    display_dashboard()
