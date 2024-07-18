import error
import gleam/dynamic
import gleam/io
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import internal/decoder
import internal/encoder
import internal/standard_io
import lsp/lsp_types
import lsp/server_capabilities
import pprint

/// Creates [server_capabilities.ServerCapabilities] with all fields set to
/// None
fn new_server_capabilities() -> server_capabilities.ServerCapabilities {
  server_capabilities.ServerCapabilities(
    completion_provider: None,
    document_symbol_provider: None,
    hover_provider: None,
    text_document_sync: None,
  )
}

/// Updates the [hover_provider] field on
/// [server_capabilities.ServerCapabilities] record
fn set_hover_provider(
  capabilities: server_capabilities.ServerCapabilities,
  hover_provider: Bool,
) {
  server_capabilities.ServerCapabilities(
    ..capabilities,
    hover_provider: Some(hover_provider),
  )
}

/// Does the necessarry work to create an [LspServer] and then returns either
/// the LspServer or an Error containing more information. 
///
/// ## TODO:
///   * passing capabilities
pub fn create_server() -> Result(lsp_types.LspServer, error.Error) {
  let capabilities =
    new_server_capabilities()
    |> set_hover_provider(True)

  read_lsp_message()
  |> server_from_init(capabilities)
}

/// Accepts a [Result] of an [lsp_types.LspMessage] and a type with
/// server capabilities and then tries to construct an [lsp_types.LspServer]
///
/// ## Example
/// ```gleam
/// let assert Ok(server) = 
///   read_lsp_message() // "InitializeResult"
///   |> server_from_init
///
/// ```
fn server_from_init(
  init_message: Result(lsp_types.LspMessage, error.Error),
  capabilities server: server_capabilities.ServerCapabilities,
) -> Result(lsp_types.LspServer, error.Error) {
  use init_message <- result.try(init_message)
  let server = case init_message {
    lsp_types.LspRequest(
      id: id,
      method: "initialize",
      params: Some(lsp_types.InitializeParams(
        root_path: root_path,
        capabilities: client,
        ..,
      )),
    ) -> {
      // WARN: For now we do not support not having a root path
      let assert Some(root_path) = root_path
      let server = lsp_types.new_server(root_path, root_path, server, client)

      let result =
        lsp_types.InitializeResult(
          capabilities: server.server_caps,
          server_info: Some(server.server_info),
        )

      lsp_types.LspResponse(id: id, result: Some(result), error: None)
      |> encoder.encode_lsp_message
      |> json.to_string
      |> create_message
      |> io.println

      Ok(server)
    }
    _ ->
      Error(error.invalid_request(
        "Method was not expected. Expected an initialize request but got "
        <> pprint.format(init_message),
      ))
  }
  server
}

fn create_message(json) {
  "Content-Length: " <> int.to_string(string.length(json)) <> "\r\n\r\n" <> json
}

type RpcMessage {
  RpcNotification(method: String)
  RpcRequest(
    id: lsp_types.LspId,
    method: String,
    // temporary
    params: dynamic.Dynamic,
  )
  RpcResponse(
    id: lsp_types.LspId,
    error: Option(dynamic.Dynamic),
    res: Option(dynamic.Dynamic),
  )
}

// rpc header looks as follows:
// Content-Length: xxxx\r\n
// \r\n
// ...
fn read_rpc_message() -> Result(String, error.Error) {
  let error = error.parse_error("Could not parse Content-Length in rpc header")
  use length <- result.try(
    standard_io.get_line()
    |> string.split_once(":")
    |> result.unwrap(or: #("", ""))
    |> pair.second
    |> string.trim
    |> int.parse
    |> result.replace_error(error.parse_error(
      "Could not parse Content-Length in rpc header",
    )),
  )
  // trimming \r\n
  standard_io.get_bytes(2)
  Ok(standard_io.get_bytes(length))
}

// TODO: 
// - Split into smaller functions
// - Move into internal/decoder
fn parse_message(message: String) -> Result(lsp_types.LspMessage, error.Error) {
  let id_decoder =
    dynamic.any([
      dynamic.decode1(lsp_types.String, dynamic.string),
      dynamic.decode1(lsp_types.Integer, dynamic.int),
    ])

  // WARN: Notification has to be decoded separately since it only consists of
  // a subset of which the other variants also consist of
  let message_decoder =
    dynamic.any([
      dynamic.decode3(
        RpcRequest,
        dynamic.field("id", id_decoder),
        dynamic.field("method", dynamic.string),
        dynamic.field("params", dynamic.dynamic),
      ),
      dynamic.decode3(
        RpcResponse,
        dynamic.field("id", id_decoder),
        dynamic.optional_field("error", dynamic.dynamic),
        dynamic.optional_field("result", dynamic.dynamic),
      ),
    ])

  let notification_decoder =
    dynamic.decode1(RpcNotification, dynamic.field("method", dynamic.string))

  let decoded_message =
    result.lazy_or(json.decode(from: message, using: message_decoder), fn() {
      json.decode(from: message, using: notification_decoder)
    })
    |> result.map_error(fn(err) {
      error.parse_error("Could not parse rpc message." <> pprint.format(err))
    })

  use decoded_message <- result.try(decoded_message)
  case decoded_message {
    RpcNotification(method: method) ->
      Ok(lsp_types.LspNotification(method, params: None))

    RpcRequest(id: id, method: method, params: params) -> {
      use parsed_params <- result.try(parse_request_params(method, params))
      Ok(lsp_types.LspRequest(id: id, method: method, params: parsed_params))
    }

    // TODO: Send response to task which awaits it -> it knows what type it
    // should parse
    RpcResponse(id: id, res: res, error: error) -> {
      case res, error {
        Some(res), None -> {
          use parsed_result <- result.try(decoder.decode_lsp_result(res))
          Ok(lsp_types.LspResponse(
            id: id,
            error: None,
            result: Some(parsed_result),
          ))
        }
        None, Some(error) -> {
          Error(error.client_error(error))
        }
        Some(_), Some(_) ->
          Error(error.invalid_request(
            "Response can only contain a result OR an error. Not both!",
          ))
        _, _ ->
          Error(error.invalid_request(
            "Response did not contain a result nor an error.",
          ))
      }
    }
  }
}

fn parse_request_params(
  method: String,
  params: dynamic.Dynamic,
) -> Result(Option(lsp_types.LspParams), error.Error) {
  case method {
    "initialize" -> decoder.decode_initalize_params(params) |> result.map(Some)
    _ -> Error(error.method_not_found("Method '" <> method <> "' not found"))
  }
}

pub fn read_lsp_message() -> Result(lsp_types.LspMessage, error.Error) {
  use message <- result.try(read_rpc_message())
  use lsp_message <- result.try(parse_message(message))
  Ok(lsp_message)
}
