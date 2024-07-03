import gleam/json
import gleeunit/should
import internal/decoder/lsp_decoder
import internal/encoder/lsp_encoder
import lsp/lsp
import lsp/lsp_types
import lsp/capabilities
import simplifile

pub fn decode_init_params_test() {
  let json =
    simplifile.read("test/init.json")
    |> should.be_ok
  let assert Ok(_) =
    json.decode(from: json, using: lsp_decoder.decode_init_params)
  Nil
}

pub fn encode_init_reponse_test() {
  let server =
    lsp.new_server(
      root_path: "foo",
      root_uri: "bar",
      capabilities: capabilities.Capabilities(capabilities.TextDocument(
        capabilities.TextDocumentCompletion(
          capabilities.CompletionItemKind([1]),
          capabilities.CompletionItem(True, True),
        ),
        capabilities.TextDocumentHover(["plain"]),
      )),
    )
  let _ =
    json.object([
      lsp_encoder.encode_capabilities(server.capabilities),
      lsp_encoder.encode_server_info(server.server_info),
    ])
    |> json.to_string
  Nil
}

pub fn decode_init_test() {
  let assert Ok(json) = simplifile.read("test/init.json")
  json.decode(json, lsp_decoder.decode_init_params)
  |> should.be_ok()
}
