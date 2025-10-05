import gleam/bit_array
import gleam/bytes_tree
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/option
import gleam/result
import mcp_toolkit
import mcp_toolkit/core/server
import mcp_toolkit/transport/util.{json_response, method_not_allowed, string_join}
import mist

pub fn handle_http_rpc(
  req: request.Request(mist.Connection),
  server: server.Server,
  max_body_bytes: Int,
) -> response.Response(mist.ResponseData) {
  let allowed = ["POST", "OPTIONS"]
  case req.method {
    http.Post -> process_http_rpc(req, server, max_body_bytes)
    http.Options ->
      response.new(204)
      |> response.set_header("Allow", string_join(allowed))
      |> response.set_body(mist.Bytes(bytes_tree.new()))
    _ -> method_not_allowed(allowed)
  }
}

pub fn process_http_rpc(
  req: request.Request(mist.Connection),
  server: server.Server,
  max_body_bytes: Int,
) -> response.Response(mist.ResponseData) {
  case mist.read_body(req, max_body_bytes) {
    Ok(read_req) -> {
      let body =
        bit_array.to_string(read_req.body)
        |> result.unwrap("")

      case mcp_toolkit.handle_message(server, body) {
        Ok(option.Some(json)) | Error(json) ->
          json_response(200, json.to_string(json))
        Ok(option.None) ->
          response.new(204)
          |> response.set_body(mist.Bytes(bytes_tree.new()))
      }
    }
    Error(_) ->
      json_response(
        400,
        json.object([#("error", json.string("invalid body"))])
          |> json.to_string,
      )
  }
}
