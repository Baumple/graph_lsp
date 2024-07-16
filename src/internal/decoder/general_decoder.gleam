import error
import gleam/dynamic
import gleam/result
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
