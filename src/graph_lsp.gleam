import error
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import internal/parser/parser
import logging.{Error as LogError, Info}
import lsp/builder/completion_item as comp_item
import lsp/builder/markup_content as markup
import lsp/builder/response
import lsp/lsp
import lsp/lsp_types.{
  type LspEvent, type LspMessage, type LspServer, LspNotification, LspReceived,
  LspRequest,
}
import lsp/server_capabilities as server_caps
import pprint

fn handle_error(
  server: LspServer(List(String)),
  error: error.Error,
) -> LspServer(List(String)) {
  logging.log(LogError, "Error encountered: " <> pprint.format(error))
  server
}

fn handle_message(
  server: LspServer(List(String)),
  msg: LspMessage,
) -> LspServer(List(String)) {
  case msg {
    LspNotification(method: "initialized", ..) -> {
      logging.log(Info, "Connection established.")
      server
    }

    LspNotification(
      method: "textDocument/didSave",
      params: Some(lsp_types.DidSaveTextDocumentParams(text_document: td, ..)),
    ) -> {
      let path = td.uri |> string.drop_left(7)
      io.println_error(path)
      parser.parse_file(path)
      |> result.unwrap(or: [])
      |> list.filter(parser.filter_ident)
      |> list.map(parser.get_token_text)
      |> list.unique
      |> lsp.update_server_state(server)
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
      server
    }

    LspRequest(id: id, method: "textDocument/completion", params: _) -> {
      let comp_item_from_label = fn(field: String) {
        comp_item.new_completion_item(field)
        |> comp_item.set_documentation(markup.new_markdown(
          "gleam",
          "Node: " <> field,
        ))
      }
      server.state
      |> list.map(comp_item_from_label)
      |> lsp_types.CompletionList(is_incomplete: False)
      |> lsp_types.CompletionResult
      |> response.from_result(id)
      |> lsp.send_message
      server
    }

    LspRequest(id: id, method: method, ..) -> {
      lsp_types.new_err_response(id, error.method_not_found(method))
      |> lsp.send_message
      server
    }

    _ -> {
      logging.log(LogError, "Not implemented: " <> pprint.format(msg))
      lsp_types.LspNotification(method: "error", params: option.None)
      |> lsp.send_message
      server
    }
  }
}

fn loop(
  event: LspEvent,
  server: lsp_types.LspServer(List(String)),
) -> actor.Next(LspEvent, LspServer(List(String))) {
  let LspReceived(msg) = event
  case msg {
    Ok(msg) -> handle_message(server, msg)
    Error(error) -> handle_error(server, error)
  }
  |> actor.continue
}

pub fn main() {
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
