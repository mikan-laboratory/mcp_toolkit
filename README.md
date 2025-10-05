# MCP Toolkit

MCP Toolkit is a reusable library for building [Model Context Protocol](https://modelcontextprotocol.io/) (MCP) servers in Gleam. It delivers a strongly typed server builder, complete protocol types, JSON schema helpers, and stdio plus Mist-based transports so you can add MCP support directly to your own applications.

## Features

- Typed server builder for registering tools, prompts, resources, and capability flags.
- Complete MCP protocol types with JSON encoding/decoding and schema utilities.
- Stdio transport that works on Erlang and JavaScript targets, plus Mist-powered WebSocket, SSE, and HTTP JSON-RPC helpers.
- Works on OTP 27+/Gleam 1.12+ with full test coverage via gleeunit and Birdie snapshots.

## Installation

Add the package from Hex with:

```bash
gleam add mcp_toolkit
```

If you're hacking locally you can depend on this repository directly:

```toml
[dependencies]
mcp_toolkit = { path = "../mcp_toolkit" }
```

## Quick Start

Create a module that constructs your MCP server:

```gleam
import gleam/dynamic/decode
import gleam/option.{None, Some}
import mcp_toolkit
import mcp_toolkit/core/protocol as mcp

type EchoArgs {
  EchoArgs(text: String)
}

fn decode_echo_args() -> decode.Decoder(EchoArgs) {
  use text <- decode.field("text", decode.string)
  decode.success(EchoArgs(text:))
}

fn handle_echo(request: mcp.CallToolRequest(EchoArgs)) {
  let reply =
    case request.arguments {
      Some(EchoArgs(text: text)) -> text
      None -> ""
    }

  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "You said: " <> reply,
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}

pub fn build_server() -> mcp_toolkit.Server {
  let assert Ok(schema) =
    mcp.tool_input_schema("{\"type\":\"object\",\"properties\":{\"text\":{\"type\":\"string\"}},\"required\":[\"text\"]}")

  mcp_toolkit.new("Example MCP", "0.1.0")
  |> mcp_toolkit.add_tool(
    mcp.Tool(
      name: "echo",
      input_schema: schema,
      description: Some("Echo text back to the caller"),
      annotations: None,
    ),
    decode_echo_args(),
    handle_echo,
  )
  |> mcp_toolkit.build()
}
```

Hook the server up to a transport. For stdio, use the built-in helper:

```gleam
import gleam/io
import gleam/json
import mcp_toolkit
import mcp_toolkit/transport/stdio

pub fn main() {
  let server = build_server()
  loop(server)
}

fn loop(server: mcp_toolkit.Server) {
  case stdio.read_message() {
    Ok(message) -> {
      case mcp_toolkit.handle_message(server, message) {
        Ok(Some(response)) | Error(response) ->
          io.println(json.to_string(response))
        _ -> Nil
      }
    }
    Error(_) -> Nil
  }
  loop(server)
}
```

## HTTP Transports

Mist-based WebSocket, SSE, and HTTP RPC adapters live under `mcp_toolkit/transport/`. Import them directly to mount endpoints alongside your existing Mist router:

```gleam
import mcp_toolkit/transport/rpc
import mcp_toolkit/transport/websocket
import mcp_toolkit/transport/sse
```

They expect a `mcp_toolkit.Server` and return standard Mist `Response` values, letting you integrate MCP into any Mist application.

When mounting them, start the SSE registry once and reuse it across requests. The combined `handle_sse` helper coordinates both the long-lived GET stream and the POST endpoint that delivers server responses:

```gleam
import mcp_toolkit
import mcp_toolkit/transport/rpc
import mcp_toolkit/transport/sse
import mcp_toolkit/transport/websocket

pub fn handlers(server: mcp_toolkit.Server) {
  let registry = sse.start_registry()

  let sse_handler = fn(req) {
    sse.handle_sse(req, registry, server)
  }

  let rpc_handler = fn(req) {
    rpc.handle_http_rpc(req, server, 1_000_000)
  }

  let ws_handler = fn(req) {
    websocket.handle(req, server)
  }

  // Register `sse_handler`, `rpc_handler`, and `ws_handler` with your Mist router.
}
```

The SSE handler expects an `id` query parameter on POST requests that matches the `X-Conn-Id` header assigned by the GET response, so proxy both endpoints behind the same route. The RPC helper processes JSON-RPC over plain HTTP POST and responds gracefully to browser preflight `OPTIONS` requests.

Prefer the higher-level helpers when you just need a working transport. If you need more control—perhaps to add middleware, custom headers, or alternate routing—you can still call the constituent functions directly:

```gleam
import gleam/http
import mcp_toolkit/transport/rpc
import mcp_toolkit/transport/sse
import mcp_toolkit/transport/util

fn custom_router(req, registry, server) {
  case req.method {
    http.Get -> sse.handle_get(req, registry)
    http.Post -> sse.handle_post(req, registry, server)
    _ -> util.method_not_allowed(["GET", "POST"])
  }
}

fn custom_rpc(req, server) {
  case req.method {
    http.Post -> rpc.process_http_rpc(req, server, 1_000_000)
    _ -> util.method_not_allowed(["POST"])
  }
}
```

## Module Guide

- `mcp_toolkit` – high level builder/transport helpers (re-exports `core/server`).
- `mcp_toolkit/core/protocol` – MCP protocol types, decoders, and encoders.
- `mcp_toolkit/core/json_schema*` – helpers for working with JSON Schema payloads.
- `mcp_toolkit/transport/interface` – stdio transport configuration and runtime helpers.
- `mcp_toolkit/transport/stdio` – cross-platform stdio transport implementation.
- `mcp_toolkit/transport/{rpc, sse, websocket}` – Mist-based HTTP adapters.

## Development & Testing

```bash
gleam deps download
gleam format
gleam test
```

Birdie snapshot fixtures live under `birdie_snapshots/`. Run `gleam test --update-snapshots` to regenerate them when you make intentional output changes.

## Publishing Checklist

1. Update `gleam.toml` with a new version and verify package metadata.
2. Run `gleam format` and `gleam test` to ensure the release is clean.
3. Publish with `gleam package publish` (requires Hex permissions).

## Project Layout

```
src/
├── mcp_ffi.erl
├── mcp_ffi.mjs
├── mcp_toolkit.gleam
└── mcp_toolkit/
    ├── core/
    └── transport/

test/
└── ...
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
