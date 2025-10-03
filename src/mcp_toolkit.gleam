/// MCP Toolkit - Model Context Protocol helper library
///
/// This module re-exports the most commonly used server builder helpers so you
/// can construct an MCP implementation without digging through the internal
/// module layout. For protocol types (`Tool`, `Resource`, etc.) import
/// `mcp_toolkit/core/protocol` directly.
import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/option.{type Option}
import mcp_toolkit/core/protocol
import mcp_toolkit/core/server
import mcp_toolkit/transport/interface as transport

/// Server builder pipeline. Combine helpers such as `add_tool` and `build` to
/// produce an MCP server implementation.
pub type Builder =
  server.Builder

/// Handle incoming MCP JSON-RPC messages once you've built a server.
pub type Server =
  server.Server

/// Transport configuration for stdio plus helpers for building runtime loops.
pub type Transport =
  transport.Transport

pub type StdioTransport =
  transport.StdioTransport

pub type TransportMessage =
  transport.TransportMessage

pub type TransportEvent =
  transport.TransportEvent

pub type TransportInterface =
  transport.TransportInterface

/// Construct a new server builder with the given name and version.
pub fn new(name name: String, version version: String) -> Builder {
  server.new(name, version)
}

pub fn description(builder: Builder, description: String) -> Builder {
  server.description(builder, description)
}

pub fn instructions(builder: Builder, instructions: String) -> Builder {
  server.instructions(builder, instructions)
}

pub fn add_resource(
  builder: Builder,
  resource: protocol.Resource,
  handler: fn(protocol.ReadResourceRequest) ->
    Result(protocol.ReadResourceResult, String),
) -> Builder {
  server.add_resource(builder, resource, handler)
}

pub fn add_resource_template(
  builder: Builder,
  template: protocol.ResourceTemplate,
  handler: fn(protocol.ReadResourceRequest) ->
    Result(protocol.ReadResourceResult, String),
) -> Builder {
  server.add_resource_template(builder, template, handler)
}

pub fn add_tool(
  builder: Builder,
  tool: protocol.Tool,
  arguments_decoder: Decoder(arguments),
  handler: fn(protocol.CallToolRequest(arguments)) ->
    Result(protocol.CallToolResult, String),
) -> Builder {
  server.add_tool(builder, tool, arguments_decoder, handler)
}

pub fn add_prompt(
  builder: Builder,
  prompt: protocol.Prompt,
  handler: fn(protocol.GetPromptRequest) ->
    Result(protocol.GetPromptResult, String),
) -> Builder {
  server.add_prompt(builder, prompt, handler)
}

pub fn resource_capabilities(
  builder: Builder,
  subscribe: Bool,
  list_changed: Bool,
) -> Builder {
  server.resource_capabilities(builder, subscribe, list_changed)
}

pub fn prompt_capabilities(builder: Builder, list_changed: Bool) -> Builder {
  server.prompt_capabilities(builder, list_changed)
}

pub fn tool_capabilities(builder: Builder, list_changed: Bool) -> Builder {
  server.tool_capabilities(builder, list_changed)
}

pub fn enable_logging(builder: Builder) -> Builder {
  server.enable_logging(builder)
}

pub fn page_limit(builder: Builder, page_limit: Int) -> Builder {
  server.page_limit(builder, page_limit)
}

/// Finalise the builder into a server that is ready to receive messages.
pub fn build(builder: Builder) -> Server {
  server.build(builder)
}

/// Decode and execute a JSON-RPC MCP message. Returns a response JSON payload
/// when needed.
pub fn handle_message(
  server: Server,
  message: String,
) -> Result(Option(json.Json), json.Json) {
  server.handle_message(server, message)
}

/// Helper to create a transport implementation for the provided configuration.
pub fn create_transport(
  transport_config: Transport,
) -> Result(TransportInterface, String) {
  transport.create_transport(transport_config)
}
