import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/option
import mcp_toolkit_gleam/core/server
import mist

/// Handle a WebSocket endpoint for MCP using text JSON-RPC messages.
/// The provided server handles each incoming message and any response is sent
/// back to the client as a text frame.
pub fn handle(
  req: request.Request(mist.Connection),
  srv: server.Server,
) -> response.Response(mist.ResponseData) {
  let on_init = fn(_conn: mist.WebsocketConnection) { #(srv, option.None) }

  let on_close = fn(_state: server.Server) { Nil }

  let ws_handler = fn(
    state: server.Server,
    msg: mist.WebsocketMessage(Nil),
    conn: mist.WebsocketConnection,
  ) {
    case msg {
      mist.Text(text) -> {
        case server.handle_message(state, text) {
          Ok(option.Some(j)) -> {
            let _ = mist.send_text_frame(conn, json.to_string(j))
            mist.continue(state)
          }
          Error(j) -> {
            let _ = mist.send_text_frame(conn, json.to_string(j))
            mist.continue(state)
          }
          _ -> mist.continue(state)
        }
      }
      _ -> mist.continue(state)
    }
  }

  mist.websocket(
    request: req,
    handler: ws_handler,
    on_init: on_init,
    on_close: on_close,
  )
}
