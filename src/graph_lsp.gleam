import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import lsp/builder/completion_item as comp_item
import lsp/builder/markup_content as markup
import lsp/lsp
import lsp/lsp_types.{
  type LspEvent, type LspServer, LspNotification, LspReceived, LspRequest,
}
import lsp/server_capabilities as server_caps
import pprint

fn loop(
  event: LspEvent,
  server: lsp_types.LspServer(List(String)),
) -> actor.Next(LspEvent, LspServer(List(String))) {
  case event {
    LspReceived(msg) ->
      case msg {
        LspNotification(method: "initialized", ..) -> {
          io.println_error("Connection established")
        }

        LspRequest(id: id, method: "textDocument/hover", ..) -> {
          lsp_types.new_ok_response(
            id,
            lsp_types.HoverResult(markup.new_markdown(
              "gleam",
              "Could be a node for all i know",
            )),
          )
          |> lsp.send_message
        }

        LspRequest(id: id, method: "textDocument/completion", params: _) -> {
          let completion_list =
            server.state
            |> list.map(fn(field) {
              comp_item.new_completion_item(field)
              |> comp_item.set_documentation(markup.new_markdown(
                "gleam",
                "Node: " <> field,
              ))
            })
            |> lsp_types.CompletionList(is_incomplete: False)

          lsp_types.new_ok_response(
            id,
            lsp_types.CompletionResult(completion_list),
          )
          |> lsp.send_message
        }
        _ -> io.println_error("Not implemented: " <> pprint.format(msg))
      }
  }
  actor.continue(server)
}

fn just_panic() {
  panic
}

fn panic_text(m) {
  io.println_error("Somnethings fucky: " <> pprint.format(m))
  panic as { "Something fucked up: " <> pprint.format(m) }
}

fn with_main() {
  let caps =
    server_caps.new_server_capabilities()
    |> server_caps.set_hover_provider(True)
    |> server_caps.set_completion_provider(server_caps.CompletionOptions(
      resolve_provider: Some(False),
      trigger_characters: Some(string.to_graphemes(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
      )),
    ))

  lsp.create_server([], caps)
  |> result.map_error(panic_text)
  |> result.lazy_unwrap(just_panic)
  |> lsp.start_with_main(loop)
  process.sleep_forever()
}

pub fn main() {
  with_main()
}
