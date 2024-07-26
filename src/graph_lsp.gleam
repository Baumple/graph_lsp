import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import lsp/lsp
import lsp/lsp_types.{
  type LspEvent, type LspServer, LspNotification, LspReceived, LspRequest,
  LspResponse,
}
import lsp/server_capabilities as server
import pprint

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
                  lsp_types.new_completion_item("test"),
                  lsp_types.new_completion_item("test2")
                    |> lsp_types.set_documentation(md_string("Hello")),
                  lsp_types.new_completion_item("test3")
                    |> lsp_types.set_deprecated(True),
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

fn completion_handler(
  server: lsp_types.LspServer(List(String)),
  id: lsp_types.LspId,
  _params: lsp_types.LspParams,
) -> #(lsp_types.LspServer(List(String)), lsp_types.LspMessage) {
  let comp_res =
    server.state
    |> list.map(lsp_types.new_completion_item)
    |> list.map(fn(item) {
      lsp_types.set_documentation(
        item,
        md_string("Node with the name " <> item.label),
      )
    })
    |> lsp_types.CompletionList(False, _)
    |> lsp_types.CompletionResult

  #(server, lsp_types.new_ok_response(id, comp_res))
}

fn hover_handler(
  server: lsp_types.LspServer(List(String)),
  id: lsp_types.LspId,
  params: lsp_types.LspParams,
) -> #(lsp_types.LspServer(List(String)), lsp_types.LspMessage) {
  let assert lsp_types.HoverParams(text_document: _, position: _) = params

  let result = lsp_types.HoverResult(md_string("This is a hover response!"))
  #(server, lsp_types.new_ok_response(id, result))
}

// Testing only
fn with_handlers() {
  lsp.new_server([""])
  |> lsp.set_hover_handler(hover_handler)
  |> lsp.set_completion_handler(
    completion_handler,
    server.CompletionOptions(Some(False), Some(string.to_graphemes("abc"))),
  )
  |> lsp.start_with_handlers()
  process.sleep_forever()
}

fn with_main() {
  let caps =
    server.new_server_capabilities()
    |> server.set_hover_provider(True)
    |> server.set_completion_provider(server.CompletionOptions(
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
  let _ = with_handlers()
}
