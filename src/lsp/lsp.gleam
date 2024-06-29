import decoder/lsp_decoder
import encoder/lsp_encoder
import gleam/int
import gleam/io
import gleam/json
import gleam/option
import gleam/result
import gleam/string
import lsp/lsp_types
import rpc/rpc_types
import error
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
  init_message: Result(lsp_types.LspMessage(a), error.Error),
) -> Result(lsp_types.LspServer, error.MethodError) {
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

pub fn read_lsp_message() -> Result(lsp_types.LspMessage(a), error.DecodeError) {
  use rpc_message <- result.try(rpc.read_rpc_message())
}
