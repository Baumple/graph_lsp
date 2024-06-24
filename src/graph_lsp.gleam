import gleam/erlang/process
import gleam/int
import gleam/option.{type Option}
import gleam/pair
import gleam/result
import gleam/string
import lsp
import lsp_types
import standard_io.{log}

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
    Error(_) -> panic
  }
}

fn loop(state: lsp_types.LspServer) {
  let _lsp_message =
    lsp.read_lsp_message()
    |> handle_error

  loop(state)
}

pub fn main() {
  initialize()
  |> handle_error
  |> loop

  process.sleep_forever()
}
