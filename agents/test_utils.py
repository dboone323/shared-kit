#!/usr/bin/env python3
"""
Unit tests for agents.utils module.
"""

import os
import sys
import unittest
from unittest.mock import patch

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from agents.utils import safe_run, user_log


class TestSafeRun(unittest.TestCase):
    """Test cases for safe_run function."""
    
    def test_safe_run_without_shell(self):
        """Test safe_run without shell execution."""
        result = safe_run(["echo", "hello"], capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn("hello", result.stdout)
    
    def test_safe_run_with_shell_not_allowed(self):
        """Test safe_run raises error when shell is used without permission."""
        # Ensure ALLOW_SHELL is not set
        if "ALLOW_SHELL" in os.environ:
            del os.environ["ALLOW_SHELL"]
        if "ALLOWED_SHELL_COMMANDS" in os.environ:
            del os.environ["ALLOWED_SHELL_COMMANDS"]
        
        with self.assertRaises(PermissionError):
            safe_run("echo hello", shell=True)
    
    def test_safe_run_with_shell_allowed_by_env(self):
        """Test safe_run allows shell when ALLOW_SHELL is set."""
        os.environ["ALLOW_SHELL"] = "true"
        try:
            result = safe_run("echo hello", shell=True, capture_output=True)
            self.assertEqual(result.returncode, 0)
        finally:
            del os.environ["ALLOW_SHELL"]
    
    def test_safe_run_with_allowed_shell_command(self):
        """Test safe_run allows specific commands via ALLOWED_SHELL_COMMANDS."""
        os.environ["ALLOWED_SHELL_COMMANDS"] = "echo,ls,pwd"
        try:
            result = safe_run("echo test", shell=True, capture_output=True)
            self.assertEqual(result.returncode, 0)
        finally:
            del os.environ["ALLOWED_SHELL_COMMANDS"]


class TestUserLog(unittest.TestCase):
    """Test cases for user_log function."""
    
    @patch('agents.utils.logger')
    def test_user_log_basic(self, mock_logger):
        """Test basic user_log functionality."""
        user_log("Test message")
        mock_logger.info.assert_called_once_with("Test message")
    
    @patch('agents.utils.logger')
    def test_user_log_with_level(self, mock_logger):
        """Test user_log with different levels."""
        user_log("Error message", level="error")
        mock_logger.error.assert_called_once_with("Error message")
        
        user_log("Warning message", level="warning")
        mock_logger.warning.assert_called_once_with("Warning message")
    
    @patch('agents.utils.logger')
    def test_user_log_with_context(self, mock_logger):
        """Test user_log with additional context."""
        user_log("Task completed", task_id="123", status="success")
        # Check that the logger was called with a message containing context
        call_args = mock_logger.info.call_args[0][0]
        self.assertIn("Task completed", call_args)
        self.assertIn("task_id=123", call_args)
        self.assertIn("status=success", call_args)
    
    @patch('sys.stdout')
    @patch('agents.utils.logger')
    def test_user_log_to_stdout(self, mock_logger, mock_stdout):
        """Test user_log prints to stdout when LOG_TO_STDOUT is set."""
        os.environ["LOG_TO_STDOUT"] = "true"
        try:
            user_log("Test message")
            # Verify logger was called
            mock_logger.info.assert_called_once()
        finally:
            del os.environ["LOG_TO_STDOUT"]


if __name__ == "__main__":
    unittest.main()
