import gleam/dynamic
import gleam/int
import gleam/json
import gleam/option.{type Option, Some}
import gleam/pair
import gleam/result
import gleam/string
import pprint
import standard_io

pub type ErrorCode {
  ParseError(err: String)
  InvalidRequest(err: String)
  MethodNotFound(err: String)
  InvalidParams(err: String)
  InternalError(err: String)
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

pub fn read_request() -> Result(RpcMessage, ErrorCode) {
  let assert Some(content_length) =
    standard_io.get_line()
    |> parse_content_length

  // \r\n
  standard_io.get_bytes(2)
  standard_io.get_bytes(content_length)
  |> from_json
  |> result.map_error(fn(err) { ParseError(pprint.format(err)) })
}

pub fn get_error_value(err: ErrorCode) -> Int {
  case err {
    ParseError(..) -> -32_700
    InvalidRequest(..) -> -32_600
    MethodNotFound(..) -> -32_601
    InvalidParams(..) -> -32_602
    InternalError(..) -> -32_603
  }
}

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

pub fn new_response(res res: RpcResult, id id: RpcId) -> RpcMessage {
  RpcResponse(rpc_version: "2.0", res: res, id: id)
}

fn from_json(message: String) -> Result(RpcMessage, json.DecodeError) {
  let id_decoder =
    dynamic.any([
      dynamic.decode1(StringId, dynamic.string),
      dynamic.decode1(NumberId, dynamic.int),
    ])

  let error_decoder =
    dynamic.decode3(
      RpcError,
      dynamic.field("code", dynamic.int),
      dynamic.field("message", dynamic.string),
      dynamic.optional_field("data", dynamic.string),
    )
  let result_decoder = dynamic.decode1(RpcOk, dynamic.dynamic)

  dynamic.any([
    dynamic.decode4(
      RpcRequest,
      dynamic.field("jsonrpc", dynamic.string),
      dynamic.field("method", dynamic.string),
      dynamic.field("params", dynamic.optional(dynamic.dynamic)),
      dynamic.field("id", id_decoder),
    ),
    dynamic.decode3(
      RpcResponse,
      dynamic.field("jsonrpc", dynamic.string),
      dynamic.any([
        dynamic.field("error", error_decoder),
        dynamic.field("result", result_decoder),
      ]),
      dynamic.field("id", id_decoder),
    ),
  ])
  |> json.decode(message, _)
}
