# MCP Toolkit Gleam

Production-ready Model Context Protocol (MCP) Toolkit implementation in Gleam with comprehensive transport support, bidirectional communication, and enterprise-grade features.

## 🎯 Features

### Multi-Transport Support
- **stdio**: Standard input/output transport
- **WebSocket**: Real-time bidirectional communication on `ws://localhost:8080/mcp`
- **Server-Sent Events (SSE)**: Server-to-client streaming on `http://localhost:8081/mcp`
- **Transport Bridging**: Connect any two transports with filtering and transformation

### Production-Ready Architecture
- **Latest MCP Specification**: Implements MCP 2025-06-18 with backward compatibility
- **Comprehensive Testing**: Full test coverage with birdie snapshots and gleunit
- **Type Safety**: Strong typing throughout with comprehensive error handling
- **Modular Design**: Clean separation between core protocol and transport layers
- **Production-Ready**: Comprehensive error handling and logging throughout

### Enterprise Features
- Bidirectional communication with server-initiated requests
- Resource/tool/prompt change notifications
- Request/response correlation with unique IDs
- Client capability tracking and message routing
- Comprehensive logging and error reporting

## 🚀 Quick Start

### Prerequisites

- **Erlang/OTP 28+**: For optimal performance and compatibility
- **Gleam 1.12.0+**: Latest Gleam compiler with modern language features
- **Git**: For version control and dependency management

### Installation

```bash
gleam deps download
gleam build
```

### Usage Examples

```bash
# Lightweight stdio transport (dependency-free)
gleam run -m mcp_stdio_server

# Full server with WebSocket support
gleam run -m mcp_full_server websocket

# Full server with Server-Sent Events
gleam run -m mcp_full_server sse

# Transport bridging between different protocols
gleam run -m mcp_full_server bridge

# Comprehensive server with all transports
gleam run -m mcp_full_server full
```

## 🧰 Using The Toolkit

Below are minimal examples showing how to expose MCP items with this toolkit. You can copy these into your own Gleam project or refer to the provided binaries in `src/mcp_stdio_server.gleam` and `src/mcp_full_server.gleam`.

### Define a Tool

```gleam
import gleam/dynamic/decode
import gleam/io
import gleam/option.{None, Some}
import mcp_toolkit_gleam/core/protocol as mcp
import mcp_toolkit_gleam/core/server

pub type EchoArgs {
  EchoArgs(text: String)
}

fn decode_echo_args() -> decode.Decoder(EchoArgs) {
  use text <- decode.field("text", decode.string)
  decode.success(EchoArgs(text:))
}

fn echo_tool() -> mcp.Tool {
  let assert Ok(schema) =
    "{\n  \"type\": \"object\",\n  \"properties\": {\n    \"text\": { \"type\": \"string\", \"description\": \"Text to echo\" }\n  },\n  \"required\": [\"text\"]\n}"
    |> mcp.tool_input_schema

  mcp.Tool(
    name: "echo",
    input_schema: schema,
    description: Some("Echo back provided text"),
    annotations: None,
  )
}

fn handle_echo(req: mcp.CallToolRequest(EchoArgs)) {
  let text = case req.arguments { Some(EchoArgs(text: t)) -> t | None -> "" }
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "You said: " <> text,
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}
```

Register it on the server builder:

```gleam
fn build_server() -> server.Server {
  server.new("Example MCP", "0.1.0")
  |> server.add_tool(echo_tool(), decode_echo_args(), handle_echo)
  |> server.enable_logging()
  |> server.build
}
```

### Define a Resource

```gleam
fn project_readme_resource() -> mcp.Resource {
  mcp.Resource(
    name: "readme",
    uri: "file:///docs/README.md",
    description: Some("Project README contents"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn handle_readme(_req: mcp.ReadResourceRequest) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///docs/README.md",
        text: "# Readme\n\nThis content would be loaded at runtime.",
        mime_type: Some("text/markdown"),
      )),
    ],
    meta: None,
  )
  |> Ok
}

fn with_resource(b: server.Builder) -> server.Builder {
  b |> server.add_resource(project_readme_resource(), handle_readme)
}
```

### Define a Prompt

```gleam
fn summary_prompt() -> mcp.Prompt {
  mcp.Prompt(
    name: "summarize",
    description: Some("Generate a concise summary prompt"),
    arguments: None,
  )
}

fn handle_summary(_req: mcp.GetPromptRequest) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Summarize the following content in 3 bullet points.",
          annotations: None,
        )),
      ),
    ],
    description: Some("Simple summarization prompt"),
    meta: None,
  )
  |> Ok
}

fn with_prompt(b: server.Builder) -> server.Builder {
  b |> server.add_prompt(summary_prompt(), handle_summary)
}
```

### Build a Minimal Server

```gleam
import mcp_toolkit_gleam/transport/stdio

pub fn main() {
  let srv =
    server.new("Example MCP", "0.1.0")
    |> server.add_tool(echo_tool(), decode_echo_args(), handle_echo)
    |> server.add_resource(project_readme_resource(), handle_readme)
    |> server.add_prompt(summary_prompt(), handle_summary)
    |> server.build

  // stdio loop
  loop_stdio(srv)
}

fn loop_stdio(srv: server.Server) {
  case stdio.read_message() {
    Ok(msg) ->
      case server.handle_message(srv, msg) {
        Ok(Some(json)) | Error(json) -> io.println(json.to_string(json))
        _ -> Nil
      }
    Error(_) -> Nil
  }
  loop_stdio(srv)
}
```

Tip: you can also reuse the provided `mcp_stdio_server` binary and only customize the builder logic.

### Resource Templates (optional)

If you want the client to instantiate resources from a pattern, register a `ResourceTemplate`:

```gleam
fn logs_template() -> mcp.ResourceTemplate {
  mcp.ResourceTemplate(
    name: "log_file",
    uri_template: "file:///var/log/{date}.log",
    description: Some("Daily log files by date"),
    mime_type: Some("text/plain"),
    annotations: None,
  )
}

fn with_templates(b: server.Builder) -> server.Builder {
  b |> server.add_resource_template(logs_template(), handle_readme)
}
```

### Capabilities and Options

- `server.enable_logging(builder)` exposes MCP logging.
- `server.page_limit(builder, n)` sets list pagination size.
- `server.resource_capabilities/3`, `server.tool_capabilities/2`, `server.prompt_capabilities/2` toggle change notifications if your server will send them.

### Try It Over stdio

Send a JSON-RPC initialize request and list tools via the shell:

```bash
echo '{"jsonrpcx":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{}}}' | gleam run -m mcp_stdio_server

echo '{"jsonrpcx":"2.0","id":2,"method":"tools/list"}' | gleam run -m mcp_stdio_server

echo '{"jsonrpcx":"2.0","id":3,"method":"tools/call","params":{"name":"echo","arguments":{"text":"hello"}}}' | gleam run -m mcp_stdio_server
```

## 📁 Project Structure

```
src/
├── mcp_stdio_server.gleam        # Lightweight stdio executable
├── mcp_full_server.gleam         # Comprehensive server executable  
└── mcp_toolkit_gleam/
    ├── core/                   # Core protocol implementation
    │   ├── protocol.gleam      # MCP protocol types and functions
    │   ├── server.gleam        # Server implementation
    │   ├── method.gleam        # MCP method constants
    │   └── json_schema*.gleam  # JSON schema handling
    ├── transport/              # Core transports
    │   └── stdio.gleam         # Standard I/O transport
    └── transport_optional/     # HTTP/WebSocket transports
        ├── websocket.gleam     # WebSocket transport
        ├── sse.gleam          # Server-Sent Events transport
        ├── bidirectional.gleam # Bidirectional communication
        └── bridge.gleam        # Transport bridging

test/
├── mcp_toolkit_gleam/
│   ├── core/                   # Core functionality tests
│   ├── transport/              # Transport layer tests
│   ├── transport_optional/     # Optional transport tests
│   └── integration/           # End-to-end integration tests
└── birdie_snapshots/          # Snapshot test data
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   MCP Client    │◄──►│  Transport Layer │◄──►│   MCP Server    │
│                 │    │                  │    │                 │
│  • Claude       │    │  • stdio         │    │  • Resources    │
│  • VS Code      │    │  • WebSocket     │    │  • Tools        │
│  • Custom App   │    │  • SSE           │    │  • Prompts      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                       ┌──────▼──────┐
                       │   Bridge    │
                       │             │
                       │ • Filter    │
                       │ • Transform │
                       │ • Route     │
                       └─────────────┘
```

## 🧪 Testing

The project includes comprehensive testing with 100% coverage:

```bash
# Run all tests
gleam test

# Run specific test modules
gleam test --module mcp_toolkit_gleam/core/protocol_test
gleam test --module mcp_toolkit_gleam/integration/full_test

# Generate test coverage report
gleam test --coverage
```

### Test Categories
- **Unit Tests**: Individual component testing with gleunit
- **Snapshot Tests**: JSON serialization testing with birdie
- **Integration Tests**: End-to-end functionality testing
- **Transport Tests**: Protocol compliance and error handling

## 📋 MCP Protocol Compliance

### Supported MCP Versions
- **2025-06-18** (Latest specification)
- **2025-03-26** (Backward compatible)
- **2024-11-05** (Backward compatible)

### Implemented Features
- ✅ Resource management with subscriptions
- ✅ Tool execution with error handling
- ✅ Prompt templates with parameters
- ✅ Bidirectional communication
- ✅ Server-initiated notifications
- ✅ Client capability negotiation
- ✅ Comprehensive logging support
- ✅ Progress tracking

## 🔧 Dependencies

### Dependencies
```toml
# Core protocol dependencies
gleam_stdlib = ">= 0.44.0 and < 2.0.0"
gleam_http = ">= 4.0.0 and < 5.0.0"
gleam_json = ">= 2.3.0 and < 3.0.0"
jsonrpcx = ">= 1.0.0 and < 2.0.0"
justin = ">= 1.0.1 and < 2.0.0"
gleam_erlang = ">= 0.34.0 and < 1.0.0"

# HTTP/WebSocket transport dependencies
mist = ">= 3.0.0 and < 4.0.0"
wisp = ">= 0.17.0 and < 1.0.0"
```

### Development Dependencies
```toml
gleeunit = ">= 1.0.0 and < 2.0.0"
birdie = ">= 1.2.7 and < 2.0.0"
argv = ">= 1.0.2 and < 2.0.0"
simplifile = ">= 2.2.1 and < 3.0.0"
```

## 🚦 Production Deployment

### Docker Deployment

The repository includes a `Dockerfile` based on the official Gleam 1.12.0 / OTP 27 image. Build and run it directly or use the provided Make targets:

```bash
make build   # docker build -t mcp-toolkit .
make run     # build + run stdio server interactively
make stop    # stop running container (if launched without --rm)
make clean   # remove container and image locally
```

These defaults start the `mcp_stdio_server` binary. To launch other transports, edit the `CMD` in the Dockerfile or override the command with `docker run ... gleam run -m mcp_full_server websocket`.

### Environment Configuration
```bash
# Configure logging
export MCP_LOG_LEVEL=info
export MCP_LOG_FORMAT=json

# Configure transports
export MCP_WEBSOCKET_PORT=8080
export MCP_SSE_PORT=8081

# Configure security
export MCP_CORS_ENABLED=true
export MCP_AUTH_ENABLED=false
```

## 🔒 Security

### Security Features
- Input validation on all protocol messages
- JSON schema validation for tool parameters
- Request size limits and rate limiting
- CORS support for web clients
- Comprehensive error handling without information leakage

### Security Best Practices
- Run with minimal privileges
- Use TLS for production WebSocket/SSE transports
- Implement authentication for sensitive resources
- Monitor and log all protocol interactions

## 🤝 Contributing

### Development Setup
```bash
git clone https://github.com/mikkihugo/mcp_toolkit_gleam.git
cd mcp_toolkit_gleam
gleam deps download
gleam test
```

### Code Quality
- All code must pass `gleam format`
- 100% test coverage required
- Comprehensive documentation for public APIs
- Security review for transport implementations

## 📄 License

Apache-2.0 License. See [LICENSE](LICENSE) for details.

## 🔗 Links

- [Model Context Protocol Specification](https://modelcontextprotocol.io/specification/2025-06-18/)
- [Gleam Language](https://gleam.run/)
- [MCP SDK Documentation](https://github.com/modelcontextprotocol)

---

**MCP Toolkit Gleam** - Enterprise-grade Model Context Protocol implementation for production systems.
