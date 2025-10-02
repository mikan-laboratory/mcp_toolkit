import mcp_toolkit_gleam/core/server

/// Minimal server used by the default binaries. Edit `build/0`
/// or replace the module entirely to expose your own tools,
/// resources, and prompts.
pub fn build() -> server.Server {
  server.new("MCP Toolkit Gleam", "1.0.0")
  |> server.build
}
