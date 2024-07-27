import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
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
          let completion_result =
            server.state
            |> list.map(fn(field) {
              comp_item.new_completion_item(field)
              |> comp_item.set_documentation(markup.new_markdown(
                "gleam",
                "Node: " <> field,
              ))
            })
            |> lsp_types.CompletionList(is_incomplete: False)
            |> lsp_types.CompletionResult

          lsp_types.new_ok_response(id, completion_result)
          |> lsp.send_message
        }
        _ -> io.println_error("Not implemented: " <> pprint.format(msg))
      }
  }
  actor.continue(server)
}

fn with_main() {
  let capabilities =
    server_caps.new_server_capabilities()
    |> server_caps.set_hover_provider(True)
    |> server_caps.set_completion_provider(server_caps.CompletionOptions(
      resolve_provider: Some(False),
      trigger_characters: Some(string.to_graphemes(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
      )),
    ))

  let assert Ok(server) = lsp.create_server([], capabilities)
  lsp.start_with_main(server, loop)
  process.sleep_forever()
}

pub fn main() {
  with_main()
}
