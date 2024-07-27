import lsp/lsp_types
import gleam/dynamic
import gleam/option.{type Option}

pub type RpcMessage {
  RpcNotification(method: String, params: Option(dynamic.Dynamic))
  RpcRequest(
    id: lsp_types.LspId,
    method: String,
    // temporary
    params: dynamic.Dynamic,
  )
  RpcResponse(
    id: lsp_types.LspId,
    error: Option(dynamic.Dynamic),
    res: Option(dynamic.Dynamic),
  )
}
