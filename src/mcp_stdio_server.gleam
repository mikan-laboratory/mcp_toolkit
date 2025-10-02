/// MCP Toolkit Gleam - Stdio Transport Only
/// Production-ready MCP server with stdio transport (dependency-free)
import app/server as app_server
import gleam/io
import gleam/json
import gleam/option.{Some}
import mcp_toolkit_gleam/core/server
import mcp_toolkit_gleam/transport/stdio

pub fn main() {
  io.println("MCP Toolkit Gleam - Stdio Transport")
  io.println("Production-ready MCP server with stdio transport")
  io.println("Listening for JSON-RPC messages on stdin...")

  let server = app_server.build()
  execute_stdio_message_loop(server)
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
