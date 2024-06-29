import gleam/int
import gleam/option.{type Option}
import gleam/pair
import gleam/result
import gleam/string
import lsp/lsp
import lsp/lsp_types
import pprint
import standard_io
import error
import gleam/erlang/process

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
fn handle_error(lsp) {
  case lsp {
    Ok(lsp) -> lsp
    Error(err) -> standard_io.log_error_panic(err)
  }
}

fn loop(state: lsp_types.LspServer) {
  let lsp_message =
    lsp.read_lsp_message()
    |> handle_error

  case lsp_message {
    lsp_types.LspResponse(..) -> loop(state)
    lsp_types.LspRequest(_, _) -> loop(state)
  }

  loop(state)
}

pub fn main() {
  initialize()
  |> handle_error
  |> loop
  process.sleep_forever()
}
