import gleam/erlang/process
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import lsp/lsp
import lsp/lsp_types.{
  type LspEvent, type LspServer, LspNotification, LspReceived, LspRequest,
  LspResponse,
}
import pprint

fn loop(
  event: LspEvent,
  state: lsp_types.LspServer,
) -> actor.Next(LspEvent, LspServer) {
  case event {
    LspReceived(msg) ->
      case msg {
        LspNotification(method: "initialized", ..) -> {
          io.println_error("Connection established")
        }
        LspRequest(id: id, ..) -> {
          LspResponse(
            id: id,
            result: Some(lsp_types.HoverResult(lsp_types.MarkupContent(
              kind: lsp_types.PlainText,
              value: "```gleam\n" <> "That must be a field\n" <> "```",
            ))),
            error: None,
          )
          |> lsp.send_message()
          io.println_error("Hover resulted")
        }
        _ -> io.println_error("Not implemented: " <> pprint.format(msg))
      }
  }

  actor.continue(state)
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
  |> lsp.start(loop)

  process.sleep_forever()
}
