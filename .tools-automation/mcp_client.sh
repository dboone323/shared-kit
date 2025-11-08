#!/bin/bash
# MCP client shim - forwards to root tools-automation
# This allows submodules to use MCP services without duplicating code

# Get the absolute path to the root tools-automation directory
TOOLS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Forward all arguments to the root MCP client
exec "${TOOLS_ROOT}/mcp_client.sh" "$@"
