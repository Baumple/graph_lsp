import error
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import internal/decoder/client_decoder
import internal/decoder/general_decoder
import internal/standard_io
import lsp/capabilities
import lsp/lsp_types
import pprint

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
  io.println_error(pprint.format(init_message))
  todo
}

fn create_message(json) {
  "Content-Length: " <> int.to_string(string.length(json)) <> "\r\n\r\n" <> json
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

type RpcMessage {
  RpcNotification(method: String)
  RpcRequest(
    id: String,
    method: String,
    // temporary
    params: dynamic.Dynamic,
  )
  RpcResponse(
    id: String,
    error: Option(dynamic.Dynamic),
    res: Option(dynamic.Dynamic),
  )
}

fn parse_message(message: String) -> Result(lsp_types.LspMessage, error.Error) {
  let message_decoder =
    dynamic.any([
      dynamic.decode3(
        RpcRequest,
        dynamic.field("id", dynamic.string),
        dynamic.field("method", dynamic.string),
        dynamic.field("params", dynamic.dynamic),
      ),
      dynamic.decode1(RpcNotification, dynamic.field("method", dynamic.string)),
      dynamic.decode3(
        RpcResponse,
        dynamic.field("id", dynamic.string),
        dynamic.optional_field("error", dynamic.dynamic),
        dynamic.optional_field("result", dynamic.dynamic),
      ),
    ])
  let decoded_message =
    json.decode(from: message, using: message_decoder)
    |> result.map_error(fn(err) {
      error.parse_error("Could not parse rpc message." <> pprint.format(err))
    })

  use decoded_message <- result.try(decoded_message)
  case decoded_message {
    RpcNotification(method: method) -> Ok(lsp_types.LspNotification(method))

    RpcRequest(id: id, method: method, params: params) -> {
      use parsed_params <- result.try(parse_request_params(method, params))
      Ok(lsp_types.LspRequest(
        id: Some(lsp_types.String(id)),
        method: method,
        params: parsed_params,
      ))
    }

    // TODO: Send response to task which awaits it -> it knows what type it
    // should parse
    RpcResponse(id: id, res: res, error: error) -> {
      case res, error {
        Some(res), None -> {
          use parsed_result <- result.try(general_decoder.decode_lsp_result(res))
          Ok(lsp_types.LspResponse(
            id: Some(lsp_types.String(id)),
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
    "initialize" ->
      client_decoder.decode_initalize_params(params) |> result.map(Some)
    _ -> Error(error.method_not_found("Method '" <> method <> "' not found"))
  }
}

pub fn read_lsp_message() -> Result(lsp_types.LspMessage, error.Error) {
  use message <- result.try(read_rpc_message())
  use lsp_message <- result.try(parse_message(message))
  Ok(lsp_message)
}
