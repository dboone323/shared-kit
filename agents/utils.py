#!/usr/bin/env python3
"""
Utility functions for agent modules.

Provides:
- safe_run: Safe subprocess execution with shell command controls
- user_log: Structured logging for user-facing CLI output
"""

import logging
import os
import subprocess
import sys
from typing import Any, Dict, List, Optional, Union


# Configure structured logging
logger = logging.getLogger(__name__)


def safe_run(
    cmd: Union[str, List[str]],
    check: bool = True,
    capture_output: bool = False,
    text: bool = True,
    shell: bool = False,
    **kwargs: Any
) -> subprocess.CompletedProcess:
    """
    Safe wrapper around subprocess.run with shell usage controls.
    
    Shell execution is only allowed when:
    - ALLOW_SHELL env var is set to "true", or
    - The command (if string) is in ALLOWED_SHELL_COMMANDS (comma-separated list)
    
    Args:
        cmd: Command to execute (string or list)
        check: Raise exception on non-zero exit (default: True)
        capture_output: Capture stdout/stderr (default: False)
        text: Return output as text (default: True)
        shell: Execute command through shell (default: False, requires env approval)
        **kwargs: Additional arguments passed to subprocess.run
        
    Returns:
        subprocess.CompletedProcess instance
        
    Raises:
        PermissionError: If shell=True but not allowed by environment
        subprocess.CalledProcessError: If check=True and command fails
    """
    # Check shell execution permission
    if shell:
        allow_shell = os.environ.get("ALLOW_SHELL", "").lower() == "true"
        
        if not allow_shell:
            # Check if command is in allowed list
            allowed_commands = os.environ.get("ALLOWED_SHELL_COMMANDS", "")
            allowed_list = [c.strip() for c in allowed_commands.split(",") if c.strip()]
            
            # Extract command name if cmd is a string
            cmd_name = cmd.split()[0] if isinstance(cmd, str) else ""
            
            if cmd_name not in allowed_list:
                raise PermissionError(
                    f"Shell execution not allowed. Set ALLOW_SHELL=true or add '{cmd_name}' "
                    f"to ALLOWED_SHELL_COMMANDS environment variable."
                )
    
    # Log the command being executed
    cmd_str = cmd if isinstance(cmd, str) else " ".join(cmd)
    logger.debug(f"Executing: {cmd_str}")
    
    try:
        result = subprocess.run(
            cmd,
            check=check,
            capture_output=capture_output,
            text=text,
            shell=shell,
            **kwargs
        )
        logger.debug(f"Command completed with return code: {result.returncode}")
        return result
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed with return code {e.returncode}: {cmd_str}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error running command: {e}")
        raise


def user_log(
    message: str,
    level: str = "info",
    stderr: bool = False,
    **kwargs: Any
) -> None:
    """
    Structured logging helper for user-facing CLI output.
    
    By default, uses Python logging. When LOG_TO_STDOUT environment variable
    is set to "true", also prints to stdout/stderr for direct user visibility.
    
    Args:
        message: Message to log
        level: Log level (debug, info, warning, error, critical)
        stderr: Print to stderr instead of stdout when LOG_TO_STDOUT is set
        **kwargs: Additional context to include in structured log
    """
    # Map level string to logging method
    log_methods = {
        "debug": logger.debug,
        "info": logger.info,
        "warning": logger.warning,
        "error": logger.error,
        "critical": logger.critical,
    }
    
    log_method = log_methods.get(level.lower(), logger.info)
    
    # Add structured context if provided
    if kwargs:
        extra_context = " | ".join(f"{k}={v}" for k, v in kwargs.items())
        full_message = f"{message} [{extra_context}]"
    else:
        full_message = message
    
    # Always use structured logging
    log_method(full_message)
    
    # Optionally print to stdout/stderr for user visibility
    if os.environ.get("LOG_TO_STDOUT", "").lower() == "true":
        output = sys.stderr if stderr or level.lower() in ("error", "critical") else sys.stdout
        print(full_message, file=output)
