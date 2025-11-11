#!/bin/bash
# Environment configuration for shared-kit submodule
# Sources root environment and adds submodule-specific settings

# Get the absolute path to the root tools-automation directory
TOOLS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source root environment if available
if [[ -f "${TOOLS_ROOT}/.env" ]]; then
    source "${TOOLS_ROOT}/.env"
fi

# Submodule-specific environment variables
export PROJECT_NAME="shared-kit"
SUBMODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SUBMODULE_ROOT

# MCP configuration
export MCP_SERVER_URL="${MCP_SERVER_URL:-http://127.0.0.1:5005}"
export MCP_API_VERSION="${MCP_API_VERSION:-v1}"

# Ollama configuration
export OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-http://localhost:11434}"
