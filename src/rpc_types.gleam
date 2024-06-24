import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{type Option, Some}
import gleam/pair
import gleam/result
import gleam/string
import standard_io

pub type ErrorCode {
  ParseError
  InvalidRequest
  MethodNotFound
  InvalidParams
  InternalError
}

fn parse_content_length(line: String) -> Option(Int) {
  line
  |> string.trim
  |> string.split_once(": ")
  |> result.unwrap(or: #("", ""))
  |> pair.second
  |> int.parse
  |> option.from_result
}

pub fn read_request() -> Result(RpcRequest, ErrorCode) {
  let assert Some(content_length) =
    standard_io.get_line()
    |> parse_content_length

  standard_io.get_bytes(2)
  standard_io.get_bytes(content_length)
  |> from_json_request
  |> result.replace_error(ParseError)
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

/// Converts a RpcResult into a json object
fn result_to_json(res: RpcResult) -> #(String, json.Json) {
  case res {
    RpcOk(value) -> #("result", json.string(value))
    RpcError(id, message, data) -> #(
      "error",
      [
        #("id", json.int(id)),
        #("message", json.string(message)),
        #("data", json.nullable(data, of: json.string)),
      ]
        |> json.object,
    )
  }
}

fn id_to_json(id: RpcId) -> #(String, json.Json) {
  #("id", case id {
    StringId(id) -> json.string(id)
    NumberId(id) -> json.int(id)
  })
}

/// Converts a [RpcResponse] to a json string in order to be sent to the client
pub fn to_json_response(rpc: RpcResponse) -> String {
  json.object([
    #("jsonrpc", json.string(rpc.rpc_version)),
    result_to_json(rpc.res),
    id_to_json(rpc.id),
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
    dynamic.field("params", of: dynamic.optional(dynamic.dynamic)),
    dynamic.field("id", of: id_decoder),
  )
  |> json.decode(request, _)
  |> io.debug
}
