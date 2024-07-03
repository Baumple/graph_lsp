import error
import gleam/dynamic
import gleam/json
import gleam/result
import logging
import internal/rpc/rpc_types

pub fn decode_rpc_message(json_message: String) {
  let id_decoder =
    dynamic.any([
      dynamic.decode1(rpc_types.StringId, dynamic.string),
      dynamic.decode1(rpc_types.NumberId, dynamic.int),
    ])

  let error_decoder =
    dynamic.decode3(
      rpc_types.RpcError,
      dynamic.field("code", dynamic.int),
      dynamic.field("message", dynamic.string),
      dynamic.optional_field("data", dynamic.string),
    )
  let result_decoder = dynamic.decode1(rpc_types.RpcOk, dynamic.dynamic)

  dynamic.any([
    dynamic.decode4(
      rpc_types.Request,
      dynamic.field("jsonrpc", dynamic.string),
      dynamic.field("method", dynamic.string),
      dynamic.field("params", dynamic.optional(dynamic.dynamic)),
      dynamic.optional_field("id", id_decoder),
    ),
    dynamic.decode3(
      rpc_types.Response,
      dynamic.field("jsonrpc", dynamic.string),
      dynamic.any([
        dynamic.field("error", error_decoder),
        dynamic.field("result", result_decoder),
      ]),
      dynamic.field("id", id_decoder),
    ),
  ])
  |> json.decode(json_message, _)
  |> result.map_error(fn(err) {
    logging.log_to_file(json_message)
    error.decode_rpc_error(err)
  })
}
