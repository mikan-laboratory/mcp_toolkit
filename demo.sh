#!/bin/bash

set -euo pipefail

cat <<'DEMO'
=== MCP Toolkit Gleam - Quick Demo ===

Available commands:
  • gleam run -m mcp_stdio_server
      Start the stdio-only MCP server (no external deps).

  • gleam run -m mcp_full_server serve [port]
      Launch the HTTP/WebSocket/SSE server. Defaults to the PORT env var or 8080.

Endpoints when running `serve`:
  • GET  /          -> plain text health check
  • GET  /health    -> JSON health response
  • POST /mcp       -> HTTP JSON-RPC endpoint
  • GET  /ws        -> WebSocket endpoint
  • GET  /sse       -> SSE stream (POST /sse to relay messages)

Example session:
  PORT=4000 gleam run -m mcp_full_server serve
  curl http://localhost:4000/health
  websocat ws://localhost:4000/ws

Customize the server by replacing the builder used in both binaries with your own
`server.Server` (see README for a walkthrough).

=== Happy hacking! ===
DEMO
