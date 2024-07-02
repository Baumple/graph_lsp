import gleam/json
import rpc/rpc_types
import gleam/dynamic
import logging

pub fn encode_message(
  resp: rpc_types.RpcMessage,
  decoder: fn(dynamic.Dynamic) -> json.Json,
) {
  json.object([
    #("jsonrpc", json.string(resp.rpc_version)),
    case resp {
      rpc_types.Response(res: res, ..) -> encode_result(res, decoder)
      _ -> logging.log_error_panic(resp)
    },
  ])
}

pub fn encode_id(id: rpc_types.RpcId) {
  #("id", case id {
    rpc_types.NumberId(id) -> json.int(id)
    rpc_types.StringId(id) -> json.string(id)
  })
}

pub fn encode_result(res: rpc_types.RpcResult, decoder) {
  case res {
    rpc_types.RpcOk(data) -> #("result", decoder(data))
    rpc_types.RpcError(code, message, ..) -> #(
      "error",
      json.object([
        #("code", json.int(code)),
        #("message", json.string(message)),
      ]),
    )
  }
}
