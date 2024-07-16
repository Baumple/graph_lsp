import error
import lsp/lsp
import lsp/lsp_types

fn initialize() -> Result(lsp_types.LspServer, error.Error) {
  lsp.read_lsp_message()
  |> lsp.server_from_init
}

pub fn main() {
  initialize()
}
