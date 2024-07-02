import decoder/lsp_decoder
import encoder/lsp_encoder
import error
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string
import lsp/lsp_types
import rpc/rpc
import rpc/rpc_types

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
  init_message: Result(lsp_types.LspMessage(a), error.Error),
) -> Result(lsp_types.LspServer, error.Error) {
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
    |> result.replace_error(error.init_not_received())
    |> result.map(fn(server) {
      send_init_response(server)
      server
    })

  server
}

fn create_message(json) {
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
  |> create_message
  |> io.println
}

fn rpc_to_lsp(
  rpc: rpc_types.RpcMessage,
) -> Result(lsp_types.LspMessage(a), error.Error) {
  case rpc {
    rpc_types.Response(..) -> Ok(lsp_types.LspResponse(rpc))
    rpc_types.Request(method: method, params: params, ..) ->
      parse_request(rpc, method, params)
  }
}

fn parse_request(
  rpc: rpc_types.RpcMessage,
  method: String,
  params: Option(dynamic.Dynamic),
) -> Result(lsp_types.LspMessage(a), error.Error) {
  case method {
    "initialize" -> {
      use params <- result.try(option.to_result(
        params,
        error.missing_parameters(),
      ))

      use method <- result.try(
        lsp_decoder.decode_init_params(params)
        |> result.map_error(error.decode_params_error),
      )

      Ok(lsp_types.LspRequest(rpc_request: rpc, method: method))
    }

    "initialized" -> Ok(lsp_types.LspRequest(rpc, lsp_types.Initialized))

    _ ->
      Ok(lsp_types.LspRequest(
        rpc_request: rpc,
        method: lsp_types.UnimplementedMethod(name: method),
      ))
  }
}

pub fn read_lsp_message() -> Result(lsp_types.LspMessage(a), error.Error) {
  use rpc_message <- result.try(rpc.read_rpc_message())
  use lsp_message <- result.try(rpc_to_lsp(rpc_message))
  Ok(lsp_message)
}
