/// Tests for the main MCP Toolkit module
import gleam/result
import gleeunit
import gleeunit/should
import mcp_toolkit
import mcp_toolkit/transport/interface as transport

pub fn main() {
  gleeunit.main()
}

// Ensure the top-level module re-exports the builder helpers we expect.
pub fn main_module_exports_test() {
  let builder =
    mcp_toolkit.new("Test Server", "0.0.1")
    |> mcp_toolkit.description("Example description")
    |> mcp_toolkit.instructions("Example instructions")
    |> mcp_toolkit.page_limit(10)
    |> mcp_toolkit.enable_logging()

  let server = mcp_toolkit.build(builder)

  mcp_toolkit.handle_message(server, "not-json")
  |> result.is_error
  |> should.be_true()

  mcp_toolkit.create_transport(transport.Stdio(transport.StdioTransport))
  |> should.be_ok()
}
