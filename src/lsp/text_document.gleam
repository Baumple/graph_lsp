import error
import gleam/dynamic
import gleam/option.{type Option, None, Some}
import gleam/result

pub type TextDocumentIdentifier {
  TextDocumentIdentifier(uri: String)
}

/// Decodes "textDocument/didSave" parameters and returnsa [TextDocumentIdentifier]
pub fn decode_did_save(
  params: Option(dynamic.Dynamic),
) -> Result(TextDocumentIdentifier, error.Error) {
  case params {
    Some(params) ->
      dynamic.decode1(
        TextDocumentIdentifier,
        dynamic.field("uri", dynamic.string),
      )(params)
      |> result.map_error(error.decode_params_error)
    None -> Error(error.missing_parameters())
  }
}
