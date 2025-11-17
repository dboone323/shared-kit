#!/usr/bin/env python3
"""
Example demonstrating usage of agents.utils module.

This script shows how to use safe_run and user_log in practice.
"""

import os
import sys

try:
    from .utils import safe_run, user_log
except ImportError:
    from utils import safe_run, user_log


def example_safe_run():
    """Demonstrate safe_run usage."""
    user_log("=== safe_run Examples ===", level="info")
    
    # Example 1: Basic command execution
    user_log("Example 1: Basic command execution")
    result = safe_run(["echo", "Hello, World!"], capture_output=True)
    user_log(f"Output: {result.stdout.strip()}", level="info")
    
    # Example 2: Git commands
    user_log("\nExample 2: Git command")
    try:
        result = safe_run(["git", "rev-parse", "--short", "HEAD"], capture_output=True)
        user_log(f"Current commit: {result.stdout.strip()}", level="info")
    except Exception as e:
        user_log(f"Git command failed: {e}", level="error")
    
    # Example 3: Shell command (requires ALLOW_SHELL)
    user_log("\nExample 3: Shell command (will fail without ALLOW_SHELL)")
    try:
        # This will fail unless ALLOW_SHELL=true
        result = safe_run("echo test | tr 'a-z' 'A-Z'", shell=True, capture_output=True)
        user_log(f"Shell output: {result.stdout.strip()}", level="info")
    except PermissionError as e:
        user_log(f"Expected: {e}", level="warning")
        user_log("To allow shell commands, set: ALLOW_SHELL=true", level="info")


def example_user_log():
    """Demonstrate user_log usage."""
    user_log("\n=== user_log Examples ===", level="info")
    
    # Example 1: Basic logging
    user_log("Example 1: Basic info message")
    
    # Example 2: Different log levels
    user_log("Example 2: Different log levels", level="debug")
    user_log("This is a warning", level="warning")
    user_log("This is an error", level="error")
    
    # Example 3: Structured logging with context
    user_log(
        "Example 3: Task completed with structured data",
        task_id="task-123",
        status="success",
        duration_ms=1234,
        items_processed=42
    )
    
    # Example 4: Conditional stdout output
    user_log("\nExample 4: LOG_TO_STDOUT behavior")
    if os.environ.get("LOG_TO_STDOUT", "").lower() == "true":
        user_log("LOG_TO_STDOUT is enabled - you see this in stdout!", level="info")
    else:
        user_log("LOG_TO_STDOUT is disabled - only in logs", level="info")
        user_log("Set LOG_TO_STDOUT=true to see messages in stdout", level="info")


def main():
    """Run all examples."""
    user_log("Starting agents.utils example demonstrations", level="info")
    user_log("=" * 60)
    
    # Run examples
    example_safe_run()
    example_user_log()
    
    user_log("=" * 60)
    user_log("Examples completed!", level="info")
    user_log("\nTry running with: LOG_TO_STDOUT=true python3 example_usage.py")


if __name__ == "__main__":
    main()
