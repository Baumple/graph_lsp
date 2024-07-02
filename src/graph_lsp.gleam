import error
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/option.{type Option}
import gleam/pair
import gleam/result
import gleam/string
import logging
import lsp/lsp
import lsp/lsp_types

pub fn parse_content_length(line: String) -> Option(Int) {
  line
  |> string.trim
  |> string.split_once(": ")
  |> result.unwrap(or: #("", ""))
  |> pair.second
  |> int.parse
  |> option.from_result
}

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

fn loop(state: lsp_types.LspServer) {
  let lsp_message =
    lsp.read_lsp_message()
    |> handle_error

  case lsp_message {
    lsp_types.LspResponse(..) -> state
    lsp_types.LspRequest(_, method) ->
      handle_request(method, state) |> handle_error
  }
  |> loop
}

fn handle_request(
  method: lsp_types.LspMethod,
  state: lsp_types.LspServer,
) -> Result(lsp_types.LspServer, error.Error) {
  case method {
    lsp_types.Initialized -> {
      io.println_error("Connection established successfully")
      Ok(state)
    }
    lsp_types.UnimplementedMethod(method) -> {
      logging.log_error_panic("Method '" <> method <> "' not yet implemented.")
      Error(error.method_not_found(method))
    }
    _ -> Ok(state)
  }
}

pub fn main() {
  initialize()
  |> handle_error
  |> loop
  process.sleep_forever()
}
