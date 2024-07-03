import error
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import internal/decoder/lsp_decoder
import internal/encoder/lsp_encoder
import internal/rpc/rpc
import internal/rpc/rpc_types
import lsp/capabilities
import lsp/lsp_types
import lsp/text_document

pub fn new_server(
  root_path root_path: String,
  root_uri root_uri: String,
  capabilities capabilities: capabilities.Capabilities,
) {
  lsp_types.LspServer(
    root_path: root_path,
    root_uri: root_uri,
    capabilities: capabilities,
    server_info: lsp_types.ServerInfo("graph_lsp", "deez_nuts"),
  )
}

pub fn server_from_init(
  init_message: Result(lsp_types.LspMessage, error.Error),
) -> Result(lsp_types.LspServer, error.Error) {
  use init_message <- result.try(init_message)

  let server =
    case init_message {
      lsp_types.LspRequest(_, lsp_method) ->
        case lsp_method {
          lsp_types.Initialize(
            name: _,
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
    |> result.map(send_init_response)

  use initialize <- result.try(read_lsp_message())
  case
    expect_request(initialize)
    |> method_to_be("initialized")
  {
    Ok(..) -> server
    Error(..) -> Error(Nil)
  }
  |> result.replace_error(error.init_not_received())
}

pub fn expect_request(
  message: lsp_types.LspMessage,
) -> Option(lsp_types.LspMethod) {
  case message {
    lsp_types.LspRequest(method: method, ..) -> Some(method)
    _ -> None
  }
}

pub fn method_to_be(
  method: Option(lsp_types.LspMethod),
  expected: String,
) -> Result(lsp_types.LspMethod, Nil) {
  case method {
    Some(method) if method.name == expected -> Ok(method)
    _ -> Error(Nil)
  }
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

  server
}

fn rpc_to_lsp(
  rpc: rpc_types.RpcMessage,
) -> Result(lsp_types.LspMessage, error.Error) {
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
) -> Result(lsp_types.LspMessage, error.Error) {
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

    "initialized" -> Ok(lsp_types.LspRequest(rpc, lsp_types.new_initialized()))

    "textDocument/" <> td_method -> parse_td_method(rpc, td_method, params)

    _ ->
      Ok(lsp_types.LspRequest(
        rpc_request: rpc,
        method: lsp_types.Unimplemented(name: method),
      ))
  }
}

/// Parses a textDocument submethod
fn parse_td_method(
  rpc: rpc_types.RpcMessage,
  td_method: String,
  params: Option(dynamic.Dynamic),
) -> Result(lsp_types.LspMessage, error.Error) {
  case td_method {
    "didSave" -> {
      use params <- result.try(text_document.decode_did_save(params))
      Ok(lsp_types.LspRequest(
        rpc_request: rpc,
        method: lsp_types.new_did_save(params),
      ))
    }
    _ -> error.method_not_found("textDocument/" <> td_method) |> Error
  }
}

pub fn read_lsp_message() -> Result(lsp_types.LspMessage, error.Error) {
  use rpc_message <- result.try(rpc.read_rpc_message())
  use lsp_message <- result.try(rpc_to_lsp(rpc_message))
  Ok(lsp_message)
}
