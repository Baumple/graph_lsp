
pub fn new_response(res res: RpcResult, id id: RpcId) -> RpcMessage {
  RpcResponse(rpc_version: "2.0", res: res, id: id)
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
pub fn read_rpc_message() -> Result(RpcMessage, error.Error) {
  let assert Some(content_length) =
    standard_io.get_line()
    |> parse_content_length

  // \r\n
  standard_io.get_bytes(2)
  standard_io.get_bytes(content_length)
  |> rpc_decoder.decode_rpc_message
}
