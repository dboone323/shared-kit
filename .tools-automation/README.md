# MCP Kit for shared-kit

This directory contains the Model Context Protocol (MCP) integration kit for the shared-kit submodule.

## Overview

The MCP kit provides a lightweight interface to the centralized MCP server running in the root `tools-automation` workspace. This allows shared-kit to leverage AI capabilities without duplicating infrastructure.

## Files

- **mcp_client.sh** - Shim script that forwards requests to the root MCP client
- **mcp_config.json** - Project-specific MCP configuration
- **env.sh** - Environment variables for this submodule
- **simple_mcp_check.sh** - Health check script for MCP connectivity

## Quick Start

### 1. Check MCP Health

```bash
./.tools-automation/simple_mcp_check.sh
```

### 2. Use MCP Client

```bash
# Register this agent
./.tools-automation/mcp_client.sh register shared-kit-agent

# Run a command
./.tools-automation/mcp_client.sh run shared-kit-agent analyze --execute
```

## Documentation

For complete documentation, see:

- [MCP Endpoints](../../docs/MCP_ENDPOINTS.md)
- [Root README](../../README.md)

## Troubleshooting

Run health check: `./.tools-automation/simple_mcp_check.sh`

For detailed troubleshooting, see the root MCP documentation.
