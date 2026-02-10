#!/bin/bash
# shellcheck disable=SC2154
# Simple MCP health check for HabitQuest
# Verifies connectivity to MCP server and Ollama

set -e

# Source environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/env.sh"

echo "🔍 MCP Health Check for ${PROJECT_NAME}"
echo "========================================="

# Check MCP server
echo -n "MCP Server (${MCP_SERVER_URL}): "
if curl -s -f -H "X-Auth-Token: ${MCP_AUTH_TOKEN}" "${MCP_SERVER_URL}/v1/health" >/dev/null 2>&1; then
	echo "✅ OK"
else
	echo "❌ FAILED"
	echo "  Try: python3 ${TOOLS_ROOT}/mcp_server.py"
fi

# Check Ollama
echo -n "Ollama (${OLLAMA_ENDPOINT}): "
if curl -s -f "${OLLAMA_ENDPOINT}/api/tags" >/dev/null 2>&1; then
	echo "✅ OK"
else
	echo "❌ FAILED"
	echo "  Try: ollama serve"
fi

echo ""
echo "✓ Health check complete"
