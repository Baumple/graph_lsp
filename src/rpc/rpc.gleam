import decoder/rpc_decoder
import error
import gleam/int
import gleam/option.{type Option, Some}
import gleam/pair
import gleam/result
import gleam/string
import rpc/rpc_types
import standard_io

pub fn new_response(
  res res: rpc_types.RpcResult,
  id id: rpc_types.RpcId,
) -> rpc_types.RpcMessage {
  rpc_types.Response(rpc_version: "2.0", res: res, id: id)
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

/// Reads a rpc message
pub fn read_rpc_message() -> Result(rpc_types.RpcMessage, error.Error) {
  let assert Some(content_length) =
    standard_io.get_line()
    |> parse_content_length

  // \r\n
  standard_io.get_bytes(2)
  standard_io.get_bytes(content_length)
  |> rpc_decoder.decode_rpc_message
}
