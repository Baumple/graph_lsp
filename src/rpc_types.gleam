import gleam/dynamic
import gleam/io
import gleam/json
import gleam/option.{type Option}

// const parse_error = -32_700
// const invalid_request = -32_600
// const method_not_found = -32_601
// const invalid_params = -32_602
// const internal_error = -32_603

pub type ErrorCode {
  ParseError
  InvalidRequest
  MethodNotFound
  InvalidParams
  InternalError
}

pub fn get_error_value(err: ErrorCode) -> Int {
  case err {
    ParseError -> -32_700
    InvalidRequest -> -32_600
    MethodNotFound -> -32_601
    InvalidParams -> -32_602
    InternalError -> -32_603
  }
}

pub type RpcRequest {
  RpcRequest(
    rpc_version: String,
    method: String,
    params: Option(dynamic.Dynamic),
    id: RpcId,
  )
}

pub type RpcId {
  StringId(id: String)
  NumberId(id: Int)
  Null
}

pub type RpcResult {
  RpcOk(value: String)
  RpcError(code: Int, message: String, data: Option(String))
}

pub type RpcResponse {
  RpcResponse(rpc_version: String, res: RpcResult, id: RpcId)
}

pub fn new_response(res res: RpcResult, id id: RpcId) -> RpcResponse {
  RpcResponse(rpc_version: "2.0", res: res, id: id)
}

pub fn with_version(rpc: RpcResponse, rpc_version: String) -> RpcResponse {
  RpcResponse(..rpc, rpc_version: rpc_version)
}

pub fn new_error(code: Int, message: String, data: Option(String)) -> RpcResult {
  RpcError(code, message, data)
}

/// Converts a RpcResult into a json object
fn build_result_object(res: RpcResult) -> json.Json {
  case res {
    RpcOk(value) -> [#("value", json.string(value))]
    RpcError(id, message, data) -> [
      #("id", json.int(id)),
      #("message", json.string(message)),
      #("data", json.nullable(data, of: json.string)),
    ]
  }
  |> json.object
}

/// Converts a [RpcResponse] to a json string in order to be sent to the client
pub fn to_json_response(rpc: RpcResponse) -> String {
  let rpc: RpcResponse = rpc
  json.object([
    #("jsonrpc", json.string(rpc.rpc_version)),
    #("result", build_result_object(rpc.res)),
  ])
  |> json.to_string
}

pub fn from_json_request(
  request: String,
) -> Result(RpcRequest, json.DecodeError) {
  let id_decoder =
    dynamic.any([
      dynamic.decode1(StringId, dynamic.string),
      dynamic.decode1(NumberId, dynamic.int),
    ])

  dynamic.decode4(
    RpcRequest,
    dynamic.field("jsonrpc", of: dynamic.string),
    dynamic.field("method", of: dynamic.string),
    dynamic.optional_field("params", of: dynamic.dynamic),
    dynamic.field("id", of: id_decoder),
  )
  |> json.decode(request, _)
  |> io.debug
}
