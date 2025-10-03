import gleam/bit_array
import gleam/bytes_tree
import gleam/dict

// import gleam/http
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/otp/actor
import gleam/result
import gleam/string_tree
import mcp_toolkit/core/server
import mist

pub type SseMsg {
  Push(String)
  Stop
}

pub type RegistryMsg {
  Alloc(process.Subject(String))
  Put(String, process.Subject(SseMsg))
  Remove(String)
  Get(String, process.Subject(option.Option(process.Subject(SseMsg))))
}

pub fn start_registry() -> process.Subject(RegistryMsg) {
  let loop = fn(
    state: #(dict.Dict(String, process.Subject(SseMsg)), Int),
    msg: RegistryMsg,
  ) {
    let #(table, next_id) = state
    case msg {
      Alloc(reply) -> {
        let id = "sse_" <> int.to_string(next_id)
        process.send(reply, id)
        actor.continue(#(table, next_id + 1))
      }
      Put(id, subj) -> actor.continue(#(dict.insert(table, id, subj), next_id))
      Remove(id) -> actor.continue(#(dict.delete(table, id), next_id))
      Get(id, reply) -> {
        let subject_opt = case dict.get(table, id) {
          Ok(s) -> option.Some(s)
          Error(_) -> option.None
        }
        process.send(reply, subject_opt)
        actor.continue(state)
      }
    }
  }

  let assert Ok(started) =
    actor.new(#(dict.new(), 1))
    |> actor.on_message(loop)
    |> actor.start

  started.data
}

pub fn handle_get(
  req: request.Request(mist.Connection),
  registry: process.Subject(RegistryMsg),
) -> response.Response(mist.ResponseData) {
  let id_reply = process.new_subject()
  process.send(registry, Alloc(id_reply))
  let assert Ok(id) = process.receive(id_reply, within: 500)

  let initial =
    response.new(200)
    |> response.set_header("X-Conn-Id", id)

  let init = fn(subject: process.Subject(SseMsg)) {
    process.send(registry, Put(id, subject))
    Ok(actor.initialised(id))
  }
  let loop = fn(state: String, message: SseMsg, conn: mist.SSEConnection) {
    case message {
      Push(text) -> {
        let event =
          string_tree.from_string(text)
          |> mist.event
          |> mist.event_name("mcp-message")
        let _ = mist.send_event(conn, event)
        actor.continue(state)
      }
      Stop -> actor.stop()
    }
  }
  mist.server_sent_events(
    request: req,
    initial_response: initial,
    init: init,
    loop: loop,
  )
}

pub fn handle_post(
  req: request.Request(mist.Connection),
  registry: process.Subject(RegistryMsg),
  srv: server.Server,
) -> response.Response(mist.ResponseData) {
  let id = case request.get_query(req) {
    Ok(qs) ->
      qs
      |> list.find(fn(pair) {
        let #(k, _v) = pair
        k == "id"
      })
      |> result.map(fn(pair) {
        let #(_k, v) = pair
        v
      })
      |> result.unwrap("")
    Error(_) -> ""
  }

  case id {
    "" ->
      response.new(400)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("missing id")))
    _ -> {
      case mist.read_body(req, 1_000_000) {
        Ok(req) -> {
          let body_bits = req.body
          let body = case bit_array.to_string(body_bits) {
            Ok(s) -> s
            Error(_) -> ""
          }
          let out = case server.handle_message(srv, body) {
            Ok(option.Some(j)) -> json.to_string(j)
            Error(j) -> json.to_string(j)
            _ -> ""
          }
          let reply = process.new_subject()
          process.send(registry, Get(id, reply))
          let subject_opt =
            process.receive(reply, within: 200)
            |> result.unwrap(option.None)
          let _ = case subject_opt {
            option.Some(subj) -> process.send(subj, Push(out))
            option.None -> Nil
          }
          response.new(200)
          |> response.set_header("Content-Type", "application/json")
          |> response.set_body(mist.Bytes(bytes_tree.from_string(out)))
        }
        Error(_) ->
          response.new(400)
          |> response.set_body(
            mist.Bytes(bytes_tree.from_string("invalid body")),
          )
      }
    }
  }
}
