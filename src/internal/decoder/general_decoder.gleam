import error
import gleam/dynamic
import gleam/result
import internal/decoder/client_decoder
import lsp/lsp_types

pub fn decode_lsp_result(
  res: dynamic.Dynamic,
) -> Result(lsp_types.LspResult, error.Error) {
  res
  |> dynamic.any([
    dynamic.decode1(
      lsp_types.HoverResult,
      dynamic.field("value", dynamic.string),
    ),
  ])
  |> result.map_error(error.parse_error)
}

pub fn decode_initalize_params(
  params: dynamic.Dynamic,
) -> Result(lsp_types.LspParams, error.Error) {
  params
  |> dynamic.decode5(
    lsp_types.InitializeParams,
    dynamic.optional_field("processId", dynamic.int),
    dynamic.optional_field("clientInfo", client_decoder.decode_client_info),
    dynamic.optional_field("locale", dynamic.string),
    dynamic.optional_field("rootPath", dynamic.string),
    dynamic.field("capabilities", client_decoder.decode_client_capabilities),
  )
  |> result.map_error(error.parse_error)
}
