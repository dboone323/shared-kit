#!/bin/bash
# Environment configuration for shared-kit submodule
# Sources root environment and adds submodule-specific settings

# Get the absolute path to the root tools-automation directory
TOOLS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Source root environment if available
if [[ -f "${TOOLS_ROOT}/.env" ]]; then
# shellcheck disable=SC1091
	source "${TOOLS_ROOT}/.env"
fi

# Submodule-specific environment variables
# shellcheck disable=SC2034
export PROJECT_NAME="shared-kit"
SUBMODULE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SUBMODULE_ROOT

# MCP configuration
# shellcheck disable=SC2034
export MCP_SERVER_URL="${MCP_SERVER_URL:-http://127.0.0.1:5005}"
# shellcheck disable=SC2034
export MCP_API_VERSION="${MCP_API_VERSION:-v1}"

# Ollama configuration
# shellcheck disable=SC2034
export OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-http://127.0.0.1:11434}"
