import gleam/dynamic
import gleam/option.{type Option}

pub type RpcMessage {
  RpcRequest(
    rpc_version: String,
    method: String,
    params: Option(dynamic.Dynamic),
    id: RpcId,
  )
  RpcResponse(rpc_version: String, res: RpcResult, id: RpcId)
}

pub type RpcId {
  StringId(id: String)
  NumberId(id: Int)
}

pub type RpcResult {
  RpcOk(data: dynamic.Dynamic)
  RpcError(code: Int, message: String, data: Option(String))
}
