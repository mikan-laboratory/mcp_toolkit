import gleam/erlang/process
import gleam/string
import gleeunit
import gleeunit/should
import mcp_toolkit/transport_optional/sse

pub fn main() {
  gleeunit.main()
}

pub fn allocs_ids() {
  let registry = sse.start_registry()
  let reply = process.new_subject()
  process.send(registry, sse.Alloc(reply))
  let got = process.receive(reply, within: 500)
  let assert Ok(id) = got
  should.be_true(string.starts_with(id, "sse_"))
}
