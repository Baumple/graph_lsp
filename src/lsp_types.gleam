import rpc_types
import gleam/json

pub type LspRequest {
  LspRequest(
    headers: List(#(String, String)),
    content_part: rpc_types.RpcRequest,
  )
}

pub type Header {
  Header(content_length: Int, content_type: String)
}

pub fn to_string(request: LspRequest) -> String {
}
