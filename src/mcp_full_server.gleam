/// MCP Toolkit Gleam - Full Server with All Transports
/// Production-ready MCP server with WebSocket, SSE, and stdio transports
import argv
import gleam/bytes_tree
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{None, Some}
// import gleam/list
// import gleam/result

// import gleam/result
import dotenv_conf
import gleam/bit_array
import gleam/string
import mcp_toolkit_gleam/core/protocol as mcp
import mcp_toolkit_gleam/core/server
import mcp_toolkit_gleam/transport/stdio
import mist
import mcp_toolkit_gleam/transport_optional/websocket as ws
import mcp_toolkit_gleam/transport_optional/sse as sse

// import mcp_toolkit_gleam/transport_optional/websocket
// import mcp_toolkit_gleam/transport_optional/sse
// import mcp_toolkit_gleam/transport_optional/bidirectional
// import mcp_toolkit_gleam/transport_optional/bridge

pub fn main() {
  case argv.load().arguments {
    ["stdio"] -> execute_stdio_transport_only()
    ["websocket"] -> run_web_server(None)
    ["websocket", port_str] -> run_web_server(Some(port_str))
    ["sse"] -> run_web_server(None)
    ["full"] -> run_web_server(None)
    ["bridge"] -> run_web_server(None)
    _ -> {
      print_usage()
    }
  }
}

fn print_usage() {
  io.println("MCP Toolkit Gleam - Production-Ready MCP Server")
  io.println("")
  io.println("Usage: gleam run -- mcpserver [transport]")
  io.println("")
  io.println("Transports:")
  io.println("  stdio     - stdio transport only (dependency-free)")
  io.println("  websocket - HTTP / WebSocket / SSE on $PORT")
  io.println("  sse       - alias for 'websocket' mode")
  io.println("  full      - alias for 'websocket' mode")
  io.println("  bridge    - alias for 'websocket' mode")
  io.println("")
  io.println("Examples:")
  io.println("  gleam run -- mcpserver stdio")
  io.println("  gleam run -- mcpserver websocket")
  // io.println("  gleam run -- mcpserver full")
  io.println("")
  io.println("Note: 'websocket' mode runs an HTTP server.")
}

fn execute_stdio_transport_only() {
  io.println("Starting MCP Toolkit with stdio transport...")
  let server = create_comprehensive_production_server()
  execute_stdio_message_loop(server)
}

/// Minimal HTTP server that binds to $PORT
fn run_web_server(cli_port: option.Option(String)) {
  let env_port =
    dotenv_conf.read_file(".env", fn(file) {
      dotenv_conf.read_int_or("PORT", file, 8080)
    })

  let port = case cli_port {
    Some(p) ->
      case int.parse(p) {
        Ok(i) -> i
        Error(_) -> env_port
      }
    None -> env_port
  }

  let registry = sse.start_registry()
  let srv = create_comprehensive_production_server()

  let handler = fn(req: request.Request(mist.Connection)) -> response.Response(
    mist.ResponseData,
  ) {
    case request.path_segments(req) {
      [] ->
        response.new(200)
        |> response.set_header("Content-Type", "text/plain")
        |> response.set_body(mist.Bytes(bytes_tree.from_string("ok")))
      ["health"] ->
        response.new(200)
        |> response.set_header("Content-Type", "application/json")
        |> response.set_body(
          mist.Bytes(bytes_tree.from_string("{\"status\":\"ok\"}")),
        )
      ["mcp"] -> {
        // HTTP JSON-RPC endpoint: POST only
        case req.method {
          http.Post -> {
            case mist.read_body(req, 1_000_000) {
              Ok(req) -> {
                let body_bits = req.body
                let body = case bit_array.to_string(body_bits) {
                  Ok(s) -> s
                  Error(_) -> ""
                }
                case server.handle_message(srv, body) {
                  Ok(Some(j)) ->
                    response.new(200)
                    |> response.set_header("Content-Type", "application/json")
                    |> response.set_body(
                      mist.Bytes(bytes_tree.from_string(json.to_string(j))),
                    )
                  Error(j) ->
                    response.new(200)
                    |> response.set_header("Content-Type", "application/json")
                    |> response.set_body(
                      mist.Bytes(bytes_tree.from_string(json.to_string(j))),
                    )
                  _ ->
                    response.new(204)
                    |> response.set_body(mist.Bytes(bytes_tree.new()))
                }
              }
              Error(_) ->
                response.new(400)
                |> response.set_header("Content-Type", "text/plain")
                |> response.set_body(
                  mist.Bytes(bytes_tree.from_string("invalid body")),
                )
            }
          }
          _ ->
            response.new(405)
            |> response.set_header("Allow", "POST")
            |> response.set_body(
              mist.Bytes(bytes_tree.from_string("method not allowed")),
            )
        }
      }
      ["ws"] -> ws.handle(req, srv)
      ["sse"] -> {
        // SSE endpoint: GET establishes stream, POST sends message and relays response event
        case req.method {
          http.Get -> sse.handle_get(req, registry)
          http.Post -> sse.handle_post(req, registry, srv)
          _ ->
            response.new(405)
            |> response.set_header("Allow", "GET, POST")
            |> response.set_body(mist.Bytes(bytes_tree.from_string("method not allowed")))
        }
      }
      _ ->
        response.new(404)
        |> response.set_header("Content-Type", "text/plain")
        |> response.set_body(mist.Bytes(bytes_tree.from_string("not found")))
    }
  }

  case
    mist.new(handler) |> mist.port(port) |> mist.bind("0.0.0.0") |> mist.start
  {
    Ok(_) ->
      io.println("HTTP server started on 0.0.0.0:" <> int.to_string(port))
    Error(err) -> io.println("Failed to start server: " <> string.inspect(err))
  }
}

fn execute_stdio_message_loop(server: server.Server) -> Nil {
  case stdio.read_message() {
    Ok(msg) -> {
      case server.handle_message(server, msg) {
        Ok(Some(json)) | Error(json) -> io.println(json.to_string(json))
        _ -> Nil
      }
    }
    Error(_) -> Nil
  }
  execute_stdio_message_loop(server)
}

/// Create a comprehensive production-ready server with all capabilities
fn create_comprehensive_production_server() -> server.Server {
  server.new("MCP Toolkit Gleam", "1.0.0")
  |> configure_all_prompts()
  |> configure_all_resources()
  |> configure_all_tools()
  |> server.build
}

fn configure_all_prompts(srv: server.Builder) -> server.Builder {
  srv
  |> server.add_prompt(create_code_review_prompt(), handle_code_review_request)
  |> server.add_prompt(
    create_documentation_prompt(),
    handle_documentation_request,
  )
  |> server.add_prompt(create_testing_prompt(), handle_testing_request)
}

fn configure_all_resources(srv: server.Builder) -> server.Builder {
  srv
  |> server.add_resource(
    create_project_structure_resource(),
    handle_project_structure_request,
  )
  |> server.add_resource(
    create_api_documentation_resource(),
    handle_api_documentation_request,
  )
  |> server.add_resource(create_changelog_resource(), handle_changelog_request)
}

fn configure_all_tools(srv: server.Builder) -> server.Builder {
  srv
  |> server.add_tool(
    create_weather_tool(),
    decode_weather_request(),
    handle_weather_request,
  )
  |> server.add_tool(
    create_time_tool(),
    decode_time_request(),
    handle_time_request,
  )
  |> server.add_tool(
    create_calculate_tool(),
    decode_calculate_request(),
    handle_calculate_request,
  )
}

// Prompt definitions
fn create_code_review_prompt() {
  mcp.Prompt(
    name: "code_review",
    description: Some("Generate comprehensive code reviews with best practices"),
    arguments: Some([
      mcp.PromptArgument(
        name: "language",
        description: Some("The programming language"),
        required: Some(True),
      ),
      mcp.PromptArgument(
        name: "focus",
        description: Some(
          "Areas to focus on (security, performance, maintainability)",
        ),
        required: Some(False),
      ),
    ]),
  )
}

fn handle_code_review_request(_request) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Please review this code focusing on:\n1. Security vulnerabilities\n2. Performance optimizations\n3. Code maintainability\n4. Best practices adherence",
          annotations: None,
        )),
      ),
    ],
    description: Some("Comprehensive code review template"),
    meta: None,
  )
  |> Ok
}

fn create_documentation_prompt() {
  mcp.Prompt(
    name: "documentation",
    description: Some("Generate technical documentation"),
    arguments: Some([
      mcp.PromptArgument(
        name: "type",
        description: Some(
          "Type of documentation (API, user guide, technical spec)",
        ),
        required: Some(True),
      ),
    ]),
  )
}

fn handle_documentation_request(_request) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Generate comprehensive documentation including:\n1. Overview and purpose\n2. Usage examples\n3. API reference\n4. Best practices",
          annotations: None,
        )),
      ),
    ],
    description: Some("Technical documentation template"),
    meta: None,
  )
  |> Ok
}

fn create_testing_prompt() {
  mcp.Prompt(
    name: "testing",
    description: Some("Generate test cases and testing strategies"),
    arguments: None,
  )
}

fn handle_testing_request(_request) {
  mcp.GetPromptResult(
    messages: [
      mcp.PromptMessage(
        role: mcp.User,
        content: mcp.TextPromptContent(mcp.TextContent(
          type_: "text",
          text: "Create comprehensive test cases including:\n1. Unit tests\n2. Integration tests\n3. Edge cases\n4. Error scenarios",
          annotations: None,
        )),
      ),
    ],
    description: Some("Testing strategy template"),
    meta: None,
  )
  |> Ok
}

// Resource definitions
fn create_project_structure_resource() -> mcp.Resource {
  mcp.Resource(
    name: "project_structure",
    uri: "file:///project/structure.md",
    description: Some("Project architecture and structure documentation"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn handle_project_structure_request(_request) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///project/structure.md",
        text: "# MCP Toolkit Gleam Project Structure\n\n## Core Components\n- `core/protocol.gleam` - MCP protocol definitions\n- `core/server.gleam` - Server implementation\n- `transport/` - Transport implementations\n- `transport_optional/` - Optional transports requiring external deps\n\n## Architecture\nProduction-ready Model Context Protocol toolkit with multi-transport support.",
        mime_type: Some("text/markdown"),
      )),
    ],
    meta: None,
  )
  |> Ok
}

fn create_api_documentation_resource() -> mcp.Resource {
  mcp.Resource(
    name: "api_docs",
    uri: "file:///project/api.md",
    description: Some("API documentation and usage examples"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn handle_api_documentation_request(_request) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///project/api.md",
        text: "# MCP Toolkit API\n\n## Transports\n- stdio: Standard input/output\n- WebSocket: Real-time bidirectional\n- SSE: Server-sent events\n\n## Features\n- Multi-transport support\n- Transport bridging\n- Bidirectional communication",
        mime_type: Some("text/markdown"),
      )),
    ],
    meta: None,
  )
  |> Ok
}

fn create_changelog_resource() -> mcp.Resource {
  mcp.Resource(
    name: "changelog",
    uri: "file:///project/CHANGELOG.md",
    description: Some("Project changelog and version history"),
    mime_type: Some("text/markdown"),
    size: None,
    annotations: None,
  )
}

fn handle_changelog_request(_request) {
  mcp.ReadResourceResult(
    contents: [
      mcp.TextResource(mcp.TextResourceContents(
        uri: "file:///project/CHANGELOG.md",
        text: "# Changelog\n\n## [1.0.0] - 2024-01-01\n### Added\n- Multi-transport MCP server\n- Production-ready architecture\n- Comprehensive testing\n- Transport bridging\n- Bidirectional communication",
        mime_type: Some("text/markdown"),
      )),
    ],
    meta: None,
  )
  |> Ok
}

// Tool definitions and handlers
pub type WeatherRequest {
  WeatherRequest(location: String)
}

fn decode_weather_request() -> decode.Decoder(WeatherRequest) {
  use location <- decode.field("location", decode.string)
  decode.success(WeatherRequest(location:))
}

fn create_weather_tool() -> mcp.Tool {
  let assert Ok(schema) =
    "{
    \"type\": \"object\",
    \"properties\": {
      \"location\": {
        \"type\": \"string\",
        \"description\": \"City name or zip code\"
      }
    },
    \"required\": [\"location\"]
  }"
    |> mcp.tool_input_schema

  mcp.Tool(
    name: "get_weather",
    input_schema: schema,
    description: Some("Get current weather information for a location"),
    annotations: None,
  )
}

fn handle_weather_request(_request) {
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "Current weather information:\nTemperature: 72°F (22°C)\nConditions: Partly cloudy\nHumidity: 65%\nWind: 8 mph NW\nPressure: 30.12 in",
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}

pub type TimeRequest {
  TimeRequest(timezone: option.Option(String))
}

fn decode_time_request() -> decode.Decoder(TimeRequest) {
  use timezone <- mcp.omittable_field("timezone", decode.string)
  decode.success(TimeRequest(timezone:))
}

fn create_time_tool() -> mcp.Tool {
  let assert Ok(schema) =
    "{
    \"type\": \"object\",
    \"properties\": {
      \"timezone\": {
        \"type\": \"string\",
        \"description\": \"Timezone (e.g., UTC, America/New_York)\"
      }
    }
  }"
    |> mcp.tool_input_schema

  mcp.Tool(
    name: "get_time",
    input_schema: schema,
    description: Some("Get current time in specified timezone"),
    annotations: None,
  )
}

fn handle_time_request(_request) {
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "Current time: 2024-01-01 12:00:00 UTC\nTimezone: UTC\nDay of week: Monday\nWeek of year: 1",
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}

pub type CalculateRequest {
  CalculateRequest(expression: String)
}

fn decode_calculate_request() -> decode.Decoder(CalculateRequest) {
  use expression <- decode.field("expression", decode.string)
  decode.success(CalculateRequest(expression:))
}

fn create_calculate_tool() -> mcp.Tool {
  let assert Ok(schema) =
    "{
    \"type\": \"object\",
    \"properties\": {
      \"expression\": {
        \"type\": \"string\",
        \"description\": \"Mathematical expression to evaluate\"
      }
    },
    \"required\": [\"expression\"]
  }"
    |> mcp.tool_input_schema

  mcp.Tool(
    name: "calculate",
    input_schema: schema,
    description: Some("Evaluate mathematical expressions"),
    annotations: None,
  )
}

fn handle_calculate_request(_request) {
  mcp.CallToolResult(
    content: [
      mcp.TextToolContent(mcp.TextContent(
        type_: "text",
        text: "Expression: 2 + 2\nResult: 4\nType: Integer",
        annotations: None,
      )),
    ],
    is_error: Some(False),
    meta: None,
  )
  |> Ok
}
