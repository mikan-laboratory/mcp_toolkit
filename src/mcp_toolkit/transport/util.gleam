import gleam/bytes_tree
import gleam/http/response
import gleam/string
import mist

pub fn method_not_allowed(
  allowed: List(String),
) -> response.Response(mist.ResponseData) {
  response.new(405)
  |> response.set_header("Allow", string_join(allowed))
  |> response.set_body(mist.Bytes(bytes_tree.from_string("method not allowed")))
}

pub fn json_response(
  status: Int,
  body: String,
) -> response.Response(mist.ResponseData) {
  response.new(status)
  |> response.set_header("Content-Type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

pub fn string_join(values: List(String)) -> String {
  string.join(values, ", ")
}
