/// MCP Toolkit Gleam - Full Server with All Transports
/// Production-ready MCP server with WebSocket, SSE, and stdio transports
import app/server as app_server
import argv
import dotenv_conf
import gleam/bit_array
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import mcp_toolkit_gleam/core/server
import mcp_toolkit_gleam/transport/stdio
import mcp_toolkit_gleam/transport_optional/sse
import mcp_toolkit_gleam/transport_optional/websocket as ws
import mist

// import mcp_toolkit_gleam/transport_optional/websocket
// import mcp_toolkit_gleam/transport_optional/sse
// import mcp_toolkit_gleam/transport_optional/bidirectional
// import mcp_toolkit_gleam/transport_optional/bridge

pub fn main() {
  case argv.load().arguments {
    ["stdio"] -> execute_stdio_transport_only()
    ["serve"] -> run_web_server(None)
    ["serve", port_str] -> run_web_server(Some(port_str))
    ["websocket"] -> run_web_server(None)
    ["websocket", port_str] -> run_web_server(Some(port_str))
    _ -> print_usage()
  }
}

fn print_usage() {
  io.println("MCP Toolkit Gleam - Production-Ready MCP Server")
  io.println("")
  io.println("Usage: gleam run -- mcpserver [transport]")
  io.println("")
  io.println("Transports:")
  io.println("  stdio  - stdio transport only (dependency-free)")
  io.println("  serve  - HTTP / WebSocket / SSE on $PORT")
  io.println("  websocket - alias for 'serve' mode")
  io.println("")
  io.println("Examples:")
  io.println("  gleam run -- mcpserver stdio")
  io.println("  gleam run -- mcpserver serve")
  // io.println("  gleam run -- mcpserver full")
  io.println("")
  io.println("Note: 'websocket' mode runs an HTTP server.")
}

fn execute_stdio_transport_only() {
  io.println("Starting MCP Toolkit with stdio transport...")
  let server = app_server.build()
  execute_stdio_message_loop(server)
}

/// Minimal HTTP server that binds to $PORT
fn run_web_server(cli_port: Option(String)) {
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
  let srv = app_server.build()

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
            |> response.set_body(
              mist.Bytes(bytes_tree.from_string("method not allowed")),
            )
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
    Ok(_) -> {
      io.println("HTTP server started on 0.0.0.0:" <> int.to_string(port))
      process.sleep_forever()
    }
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
