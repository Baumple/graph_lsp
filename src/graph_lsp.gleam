import error
import gleam/erlang/process
import gleam/io
import logging
import lsp/lsp
import lsp/lsp_types

fn initialize() -> Result(lsp_types.LspServer, error.Error) {
  lsp.read_lsp_message()
  |> lsp.server_from_init
}

/// Handles an error and TODO:sends the appropriate answer to standard out
fn handle_error(res) {
  case res {
    Ok(lsp) -> lsp
    Error(err) -> logging.log_error_panic(err)
  }
}

fn loop(server_state: lsp_types.LspServer) {
  let lsp_message =
    lsp.read_lsp_message()
    |> handle_error

  case lsp_message {
    lsp_types.LspResponse(..) -> server_state
    lsp_types.LspRequest(_, method) ->
      handle_request(method, server_state) |> handle_error
  }
  |> loop
}

fn handle_request(
  method: lsp_types.LspMethod,
  server_state: lsp_types.LspServer,
) -> Result(lsp_types.LspServer, error.Error) {
  case method {
    lsp_types.Initialized(..) -> {
      io.println_error("Connection established successfully")
      Ok(server_state)
    }
    lsp_types.DidSave(name: name, document_ident: document_ident) -> {
      Ok(server_state)
    }
    lsp_types.Initialize(name: name, ..) -> Error(error.unexpected_method(name))
  }
}

pub fn main() {
  initialize()
  |> handle_error
  |> loop
  process.sleep_forever()
}
