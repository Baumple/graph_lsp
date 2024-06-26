import gleam/int
import gleam/option.{type Option}
import gleam/pair
import gleam/result
import gleam/string
import lsp
import lsp_types
import pprint
import standard_io

pub fn parse_content_length(line: String) -> Option(Int) {
  line
  |> string.trim
  |> string.split_once(": ")
  |> result.unwrap(or: #("", ""))
  |> pair.second
  |> int.parse
  |> option.from_result
}

fn initialize() -> Result(lsp_types.LspServer, lsp_types.LspError) {
  lsp.read_lsp_message()
  |> lsp.server_from_init
}

/// Handles an error and TODO:sends the appropriate answer to standard out
fn handle_error(lsp) {
  case lsp {
    Ok(lsp) -> lsp
    Error(err) -> standard_io.log_error(err)
  }
}

fn loop(state: lsp_types.LspServer) {
  let lsp_message =
    lsp.read_lsp_message()
    |> handle_error

  case lsp_message {
    lsp_types.LspRequest(_, method) ->
      case method {
        other ->
          panic as { "'" <> pprint.format(other) <> "' not yet implemented" }
      }
    lsp_types.LspResponse(..) -> loop(state)
  }

  loop(state)
}

pub fn main() {
  standard_io.init_logger()
  initialize()
  |> handle_error
  |> loop
}
