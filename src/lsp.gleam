import decoder/lsp_decoder
import gleam/dynamic
import gleam/option
import gleam/result
import lsp_types
import pprint
import rpc_types as rpc
import standard_io

pub fn server_from_init(
  init_message: Result(lsp_types.LspMessage, lsp_types.LspError),
) -> Result(lsp_types.LspServer, lsp_types.LspError) {
  use init_message <- result.try(init_message)
  let init_method = init_message.method

  Ok(case init_method {
    lsp_types.InitializeMethod(
      root_path: root_path,
      root_uri: root_uri,
      capabilities: capabilities,
    ) ->
      lsp_types.LspServer(
        root_path: root_path,
        root_uri: root_uri,
        capabilities: capabilities |> standard_io.log,
      )
  })
}

/// Converts an [RpcRequest] into an [LspRequest]
pub fn lsp_from_rcp(
  rpc: rpc.RpcRequest,
) -> Result(lsp_types.LspMessage, List(dynamic.DecodeError)) {
  case rpc.method {
    "initialize" -> {
      let params = option.to_result(rpc.params, [])
      use params <- result.try(params)
      use params <- result.try(lsp_decoder.decode_initialize_params(params))
      Ok(lsp_types.LspRequest(rpc_request: rpc, method: params))
    }
    other -> panic as { "Method '" <> other <> "' not yet implemented" }
  }
}

pub fn read_lsp_message() -> Result(lsp_types.LspMessage, lsp_types.LspError) {
  rpc.read_request()
  |> result.map_error(fn(err) {
    lsp_types.RpcError(pprint.format(err), rpc.ParseError)
  })
  |> result.try(fn(req) {
    lsp_from_rcp(req)
    |> result.map_error(fn(err) {
      lsp_types.RpcError(pprint.format(err), rpc.ParseError)
    })
  })
}
