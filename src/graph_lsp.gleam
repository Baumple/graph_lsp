import gleam/erlang/process
import gleam/io
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/result
import lsp/lsp
import lsp/lsp_types.{
  type LspEvent, type LspServer, LspNotification, LspReceived, LspRequest,
  LspResponse,
}
import pprint
import lsp/builder/completion_builder as comp_builder

fn md_string(data: String) -> lsp_types.MarkupContent {
  lsp_types.MarkupContent(
    kind: lsp_types.Markdown,
    value: "```gleam\n" <> data <> "\n```",
  )
}

fn loop(
  event: LspEvent,
  state: lsp_types.LspServer(List(String)),
) -> actor.Next(LspEvent, LspServer(List(String))) {
  case event {
    LspReceived(msg) ->
      case msg {
        LspNotification(method: "initialized", ..) -> {
          io.println_error("Connection established")
        }

        LspRequest(id: id, method: "textDocument/hover", ..) -> {
          LspResponse(
            id: id,
            result: Some(
              lsp_types.HoverResult(md_string("Could be a node for all i know")),
            ),
            error: None,
          )
          |> lsp.send_message
        }

        LspRequest(id: id, method: "textDocument/completion", params: _) -> {
          io.println_error("Got completion")
          LspResponse(
            id: id,
            result: Some(
              lsp_types.CompletionResult(lsp_types.CompletionList(
                items: [
                  comp_builder.new("test"),
                  comp_builder.new("test2")
                    |> comp_builder.set_documentation(md_string("Hello")),
                ],
                is_incomplete: False,
              )),
            ),
            error: None,
          )
          |> lsp.send_message
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
  io.println_error("Somnethings fucky: " <> pprint.format(m))
  panic as { "Something fucked up: " <> pprint.format(m) }
}

pub fn main() {
  io.println_error("Starting server..")
  lsp.create_server_with_state([])
  |> result.map_error(panic_text)
  |> result.lazy_unwrap(just_panic)
  |> lsp.start(loop)

  process.sleep_forever()
}
