import decoder/lsp_decoder
import encoder/lsp_encoder
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import lsp_types
import pprint
import rpc_types
import standard_io

pub fn new_server(
  root_path root_path: String,
  root_uri root_uri: String,
  capabilities capabilities: lsp_types.Capabilities,
) {
  lsp_types.LspServer(
    root_path: root_path,
    root_uri: root_uri,
    capabilities: capabilities,
    server_info: lsp_types.ServerInfo("graph_lsp", "deez_nuts"),
  )
}

pub fn server_from_init(
  init_message: Result(lsp_types.LspMessage(a), lsp_types.LspError(a)),
) -> Result(lsp_types.LspServer, lsp_types.LspError(a)) {
  use init_message <- result.try(init_message)

  let server =
    case init_message {
      lsp_types.LspRequest(_, lsp_method) ->
        case lsp_method {
          lsp_types.InitializeMethod(
            root_path: root_path,
            root_uri: root_uri,
            capabilities: capabilities,
          ) ->
            Ok(new_server(
              root_path: root_path,
              root_uri: root_uri,
              capabilities: capabilities,
            ))
          _ -> Error(Nil)
        }
      _ -> Error(Nil)
    }
    |> result.replace_error(lsp_types.new_init_not_received())
  case server {
    Ok(server) -> send_init_response(server)
    _ -> Nil
  }
  server
}

fn mes(json) {
  "Content-Length: " <> int.to_string(string.length(json)) <> "\r\n\r\n" <> json
}

fn send_init_response(server: lsp_types.LspServer) {
  json.object([
    #("jsonrpc", json.string("2.0")),
    #("id", json.int(1)),
    #(
      "result",
      json.object([
        lsp_encoder.encode_capabilities(server.capabilities),
        lsp_encoder.encode_server_info(server.server_info),
      ]),
    ),
  ])
  |> json.to_string
  |> mes
  |> standard_io.log
  |> io.println
}

/// Converts an [RpcRequest] into an [LspRequest]
pub fn lsp_from_rcp(
  rpc: rpc_types.RpcMessage,
) -> Result(lsp_types.LspMessage(a), List(dynamic.DecodeError)) {
  case rpc {
    rpc_types.RpcResponse(..) ->
      panic as "Receving RpcResponse not yet implemented"
    rpc_types.RpcRequest(method: method, params: params, ..) ->
      case method {
        "initialize" -> {
          let params = option.to_result(params, []) |> standard_io.log
          use params <- result.try(params)
          use method <- result.try(lsp_decoder.decode_init_params(params))
          Ok(lsp_types.LspRequest(rpc_request: rpc, method: method))
        }
        other -> panic as { "Method '" <> other <> "' not yet implemented" }
      }
  }
}

pub fn read_lsp_message() -> Result(
  lsp_types.LspMessage(a),
  lsp_types.LspError(b),
) {
  use request <- result.try(
    rpc_types.read_request()
    |> result.map_error(fn(err) { rpc_types.ParseError(err) }),
  )
  use request <- result.try(lsp_from_rcp(request) |> result.map_error(fn(err) { rpc_types.ParseError(err) }))
  Ok(request)
}
