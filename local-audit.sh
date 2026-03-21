#!/bin/bash

if [[ "${FLEET_INTERNAL}" != "1" ]]; then
  echo "❌ Error: Independent execution disabled. Please use 'python3 control/run_all.py' from the workspace root."
  exit 1
fi

# Local Audit Script
# Runs AI-based code review and security checks using local Ollama.

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
REPO_NAME=$(basename "$REPO_ROOT")

echo "🔍 Starting local audit for $REPO_NAME..."

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "❌ Error: Ollama is not running. Please start Ollama before running this script."
    exit 1
fi

# Run the centralized review script
PYTHONPATH="/Users/danielstevens/github-projects/tools-automation/src:/Users/danielstevens/github-projects/tools-automation/src/mcp-sdk" \
python3 /Users/danielstevens/github-projects/tools-automation/scripts/local_ai_review.py "$REPO_ROOT"

echo "✅ Audit complete for $REPO_NAME."
