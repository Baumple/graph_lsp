import gleam/io
import gleam/result
import lsp/lsp
import lsp/lsp_types
import pprint

fn loop(state: lsp_types.LspServer) {
  let msg = lsp.read_lsp_message()
  case msg {
    Ok(msg) ->
      case msg {
        lsp_types.LspNotification(method: "initialized", ..) -> {
          io.println_error("Connection established")
        }
        _ -> io.println_error("Not implemented: " <> pprint.format(msg))
      }
    Error(err) -> io.println_error(pprint.format(err))
  }

  loop(state)
}

fn just_panic() {
  panic
}

fn panic_text(m) {
  panic as { "Something fucked up: " <> pprint.format(m) }
}

pub fn main() {
  io.println_error("Starting server..")
  lsp.create_server()
  |> result.map_error(panic_text)
  |> result.lazy_unwrap(just_panic)
  |> loop
}
