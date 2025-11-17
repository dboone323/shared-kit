# Agents Package

Python package for workflow automation and AI-powered tools with centralized subprocess handling and structured logging.

## Overview

This package provides:
- **`agents.utils`**: Core utilities for safe subprocess execution and structured logging
- **Agent modules**: Various automation and workflow management agents

## Core Utilities

### `safe_run()`

Safe wrapper around `subprocess.run()` with shell execution controls.

**Shell execution is only allowed when:**
- `ALLOW_SHELL` environment variable is set to `"true"`, or
- The command is listed in `ALLOWED_SHELL_COMMANDS` (comma-separated list)

**Example usage:**

```python
from agents.utils import safe_run

# Safe execution without shell
result = safe_run(["git", "status"], capture_output=True)

# Shell execution (requires ALLOW_SHELL=true or command in ALLOWED_SHELL_COMMANDS)
os.environ["ALLOW_SHELL"] = "true"
result = safe_run("echo hello | grep hello", shell=True, capture_output=True)
```

**Parameters:**
- `cmd`: Command to execute (string or list)
- `check`: Raise exception on non-zero exit (default: True)
- `capture_output`: Capture stdout/stderr (default: False)
- `text`: Return output as text (default: True)
- `shell`: Execute command through shell (default: False, requires env approval)
- `**kwargs`: Additional arguments passed to subprocess.run

**Raises:**
- `PermissionError`: If shell=True but not allowed by environment
- `subprocess.CalledProcessError`: If check=True and command fails

### `user_log()`

Structured logging helper for user-facing CLI output.

By default, uses Python's `logging` module. When `LOG_TO_STDOUT` environment variable is set to `"true"`, also prints to stdout/stderr for direct user visibility.

**Example usage:**

```python
from agents.utils import user_log

# Basic logging
user_log("Task started")

# With log level
user_log("Task failed", level="error")

# With structured context
user_log("Task completed", task_id="123", status="success", duration_ms=1500)

# Enable stdout printing
os.environ["LOG_TO_STDOUT"] = "true"
user_log("This will also print to stdout")
```

**Parameters:**
- `message`: Message to log
- `level`: Log level (debug, info, warning, error, critical)
- `stderr`: Print to stderr instead of stdout when LOG_TO_STDOUT is set
- `**kwargs`: Additional context to include in structured log

## Agent Modules

The package includes the following agent modules:

- **`metrics_dashboard`**: Monitors and displays workflow metrics
- **`ai_integration`**: Handles AI model integration and coordination
- **`success_verifier`**: Verifies successful completion of tasks
- **`agent_recovery`**: Handles agent failure recovery
- **`validation_framework`**: Provides validation utilities
- **`emergency_accelerator`**: Handles urgent task acceleration
- **`max_processor`**: Maximum performance processing
- **`analytics_collector`**: Collects and aggregates analytics
- **`run_agent`**: Main agent runner and coordinator
- **`task_accelerator`**: Accelerates task execution
- **`strategy_tracker`**: Tracks execution strategies
- **`orchestrator_v2`**: Advanced workflow orchestration
- **`agent_optimizer`**: Optimizes agent performance
- **`pattern_recognizer`**: Recognizes execution patterns
- **`normalize_task_queue`**: Normalizes task queues
- **`monitor_dashboard`**: Real-time monitoring

## Running Tests

```bash
# Run unit tests
python3 agents/test_utils.py

# Test individual agent modules
cd agents
export LOG_TO_STDOUT=true
python3 metrics_dashboard.py
python3 validation_framework.py
python3 ai_integration.py
```

## Environment Variables

- **`ALLOW_SHELL`**: Set to `"true"` to allow all shell execution in `safe_run()`
- **`ALLOWED_SHELL_COMMANDS`**: Comma-separated list of allowed shell commands (e.g., `"echo,ls,pwd"`)
- **`LOG_TO_STDOUT`**: Set to `"true"` to enable stdout/stderr printing in `user_log()`

## Migration Guide

To migrate existing code to use these utilities:

### Before:
```python
import subprocess

result = subprocess.run(["git", "status"], capture_output=True, text=True)
print(f"Status: {result.stdout}")
```

### After:
```python
from agents.utils import safe_run, user_log

result = safe_run(["git", "status"], capture_output=True)
user_log(f"Status: {result.stdout}")
```

## Best Practices

1. **Use `safe_run()` instead of `subprocess.run()`** for all subprocess calls
2. **Use `user_log()` instead of `print()`** for user-facing output
3. **Always use structured logging** by passing context as kwargs to `user_log()`
4. **Avoid shell=True** unless absolutely necessary for security
5. **Set appropriate log levels**: debug, info, warning, error, critical
6. **Handle exceptions** from subprocess calls and log them appropriately

## Security Considerations

- Shell execution is disabled by default to prevent injection attacks
- Use environment variables to explicitly allow shell execution
- Prefer list-based commands over shell strings when possible
- Always validate user input before passing to subprocess calls
