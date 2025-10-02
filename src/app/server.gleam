import dotenv_conf
import examples/demo_server
import mcp_toolkit_gleam/core/server

/// Minimal server used by the default binaries. Edit `build/0`
/// or replace the module entirely to expose your own tools,
/// resources, and prompts.
pub fn build() -> server.Server {
  use file <- dotenv_conf.read_file(".env")
  let demo = dotenv_conf.read_int_or("MCP_TOOLKIT_DEMO", file, 0)

  case demo {
    1 -> demo_server.build()
    _ ->
      server.new("MCP Toolkit Gleam", "1.0.0")
      |> server.build()
  }
}
