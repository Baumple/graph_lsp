import gleam/option.{None, Some}
import lsp/lsp_types.{type LspId, type LspMessage, type LspResult, LspResponse}

/// Wraps a result in a `LspResponse` message with the associated request id.
/// Takes the result as the first value to make it more useful in piping.
pub fn from_result(res: LspResult, id: LspId) -> LspMessage {
  LspResponse(id: id, result: Some(res), error: None)
}
