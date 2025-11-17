#!/usr/bin/env python3
"""
Comprehensive test to verify all agent modules work correctly.
"""

import sys
import importlib

# List of all agent modules
AGENT_MODULES = [
    "metrics_dashboard",
    "ai_integration",
    "success_verifier",
    "agent_recovery",
    "validation_framework",
    "emergency_accelerator",
    "max_processor",
    "analytics_collector",
    "run_agent",
    "task_accelerator",
    "strategy_tracker",
    "orchestrator_v2",
    "agent_optimizer",
    "pattern_recognizer",
    "normalize_task_queue",
    "monitor_dashboard",
]

def test_module_imports():
    """Test that all agent modules can be imported."""
    print("Testing module imports...")
    failed = []
    
    for module_name in AGENT_MODULES:
        try:
            module = importlib.import_module(module_name)
            print(f"  ✓ {module_name}")
        except Exception as e:
            print(f"  ✗ {module_name}: {e}")
            failed.append(module_name)
    
    return len(failed) == 0, failed

def test_utils_import():
    """Test that utils module works."""
    print("\nTesting utils module...")
    try:
        from utils import safe_run, user_log
        print("  ✓ safe_run imported")
        print("  ✓ user_log imported")
        return True
    except Exception as e:
        print(f"  ✗ Failed to import utils: {e}")
        return False

def main():
    """Run all tests."""
    print("=" * 60)
    print("Agent Modules Comprehensive Test")
    print("=" * 60)
    
    all_passed = True
    
    # Test utils
    if not test_utils_import():
        all_passed = False
    
    # Test module imports
    success, failed = test_module_imports()
    if not success:
        print(f"\n✗ {len(failed)} modules failed to import:")
        for module in failed:
            print(f"  - {module}")
        all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("✓ All tests passed!")
        return 0
    else:
        print("✗ Some tests failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())
