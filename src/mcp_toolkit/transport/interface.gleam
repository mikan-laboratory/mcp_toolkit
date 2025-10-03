import gleam/erlang/process.{type Subject}
import gleam/io
import gleam/option.{type Option, None}
import mcp_toolkit/transport/stdio

/// Transport configuration options supported by the runtime layer.
///
/// For now only stdio is supported; HTTP transports expose their own modules
/// under `mcp_toolkit/transport` and don't integrate with this abstraction.
pub type Transport {
  Stdio(StdioTransport)
}

/// Configuration for stdio transport
pub type StdioTransport {
  StdioTransport
}

/// Message to be sent over any transport
pub type TransportMessage {
  TransportMessage(content: String, id: Option(String))
}

/// Events that can occur on a transport
pub type TransportEvent {
  MessageReceived(message: TransportMessage)
  ClientConnected(client_id: String)
  ClientDisconnected(client_id: String)
  TransportError(error: String)
}

/// Transport interface for sending and receiving messages
pub type TransportInterface {
  TransportInterface(
    send: fn(TransportMessage) -> Result(Nil, String),
    receive: fn() -> Result(TransportEvent, String),
    start: fn() -> Result(Subject(TransportEvent), String),
    stop: fn() -> Result(Nil, String),
  )
}

/// Create a transport interface for the given transport type
pub fn create_transport(
  transport: Transport,
) -> Result(TransportInterface, String) {
  case transport {
    Stdio(_) -> create_stdio_transport()
  }
}

/// Create stdio transport interface
fn create_stdio_transport() -> Result(TransportInterface, String) {
  Ok(TransportInterface(
    send: stdio_send,
    receive: stdio_receive,
    start: stdio_start,
    stop: stdio_stop,
  ))
}

// Stdio transport implementations
fn stdio_send(message: TransportMessage) -> Result(Nil, String) {
  // Send to stdout
  io.println(message.content)
  Ok(Nil)
}

fn stdio_receive() -> Result(TransportEvent, String) {
  case stdio.read_message() {
    Ok(content) -> {
      let transport_msg = TransportMessage(content: content, id: None)
      Ok(MessageReceived(transport_msg))
    }
    Error(_) -> Error("Failed to read from stdin")
  }
}

fn stdio_start() -> Result(Subject(TransportEvent), String) {
  let event_subject = process.new_subject()
  // Stdio is always available, just return the subject
  Ok(event_subject)
}

fn stdio_stop() -> Result(Nil, String) {
  Ok(Nil)
}
