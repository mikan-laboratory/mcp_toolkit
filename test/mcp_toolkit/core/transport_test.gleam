/// Tests for transport module
import gleam/option
import gleeunit
import gleeunit/should
import mcp_toolkit/transport/interface as transport

pub fn main() {
  gleeunit.main()
}

// Test transport types creation
pub fn transport_types_test() {
  let stdio_transport = transport.StdioTransport
  // Ensure constructing the stdio variant works without runtime errors
  case transport.Stdio(stdio_transport) {
    transport.Stdio(_) -> should.be_true(True)
  }
}

// Test transport message creation
pub fn transport_message_test() {
  let message = transport.TransportMessage(content: "test", id: option.None)
  let message_with_id =
    transport.TransportMessage(content: "test", id: option.Some("123"))

  message.content |> should.equal("test")
  message.id |> should.equal(option.None)

  message_with_id.content |> should.equal("test")
  message_with_id.id |> should.equal(option.Some("123"))
}

// Test transport events
pub fn transport_events_test() {
  let message = transport.TransportMessage(content: "test", id: option.None)
  let received_event = transport.MessageReceived(message)
  let connected_event = transport.ClientConnected("client-123")
  let disconnected_event = transport.ClientDisconnected("client-123")
  let error_event = transport.TransportError("connection failed")

  // Test event types are distinct
  received_event |> should.not_equal(connected_event)
  connected_event |> should.not_equal(disconnected_event)
  disconnected_event |> should.not_equal(error_event)
}

// Test stdio transport creation
pub fn stdio_transport_creation_test() {
  let stdio_config = transport.StdioTransport
  let stdio_transport = transport.Stdio(stdio_config)

  case transport.create_transport(stdio_transport) {
    Ok(_interface) -> {
      // Test that interface is created successfully
      should.be_true(True)
    }
    Error(_) -> should.fail()
  }
}

// Test transport interface structure
pub fn transport_interface_test() {
  let stdio_transport = transport.Stdio(transport.StdioTransport)

  case transport.create_transport(stdio_transport) {
    Ok(_interface) -> {
      // Interface should be created successfully for stdio
      should.be_true(True)
    }
    Error(_msg) -> {
      // Should not fail for stdio transport
      should.fail()
    }
  }
}

pub fn transport_interface_send_test() {
  let stdio_transport = transport.Stdio(transport.StdioTransport)

  case transport.create_transport(stdio_transport) {
    Ok(iface) -> {
      let transport.TransportInterface(send:, ..) = iface
      send(transport.TransportMessage(content: "", id: option.None))
      |> should.be_ok()
    }
    Error(_msg) -> should.fail()
  }
}
