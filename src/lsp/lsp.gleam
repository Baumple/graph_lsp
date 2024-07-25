import error
import gleam/dynamic
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/pair
import gleam/result
import gleam/string
import internal/decoder
import internal/encoder
import internal/rpc_types.{RpcNotification, RpcRequest, RpcResponse}
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
) -> server_capabilities.ServerCapabilities {
  server_capabilities.ServerCapabilities(
    ..capabilities,
    hover_provider: Some(hover_provider),
  )
}

fn set_completion_provider(
  capabilities: server_capabilities.ServerCapabilities,
  completion_options: server_capabilities.CompletionOptions,
) -> server_capabilities.ServerCapabilities {
  server_capabilities.ServerCapabilities(
    ..capabilities,
    completion_provider: Some(completion_options),
  )
}

/// Does the necessarry work to create an [LspServer] and then returns either
/// the LspServer or an Error containing more information. 
///
/// ## TODO:
///   * passing capabilities
pub fn create_server(
  initial_state: a,
) -> Result(lsp_types.LspServer(a), error.Error) {
  let capabilities =
    new_server_capabilities()
    |> set_hover_provider(True)
    |> set_completion_provider(server_capabilities.CompletionOptions(
      resolve_provider: None,
      trigger_characters: Some(string.to_graphemes(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
      )),
    ))

  read_lsp_message()
  |> server_from_init(initial_state, capabilities)
}

/// Checks for input in stdin, parses it and sends a message to the evaluator
/// actor if it could parse succesful 
fn read_process(server_subject: process.Subject(lsp_types.LspEvent)) {
  case read_lsp_message() {
    Ok(msg) -> process.send(server_subject, lsp_types.LspReceived(msg))
    Error(err) -> io.println_error("Some error occured: " <> pprint.format(err))
  }
  read_process(server_subject)
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
  initial_state: a,
  capabilities server: server_capabilities.ServerCapabilities,
) -> Result(lsp_types.LspServer(a), error.Error) {
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
      let server =
        lsp_types.new_server(
          root_path,
          root_path,
          server,
          client,
          initial_state,
        )

      let result =
        lsp_types.InitializeResult(
          capabilities: server.server_caps,
          server_info: Some(server.server_info),
        )

      lsp_types.LspResponse(id: id, result: Some(result), error: None)
      |> send_message

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

pub type CompletionHandler(a) =
  fn(lsp_types.LspServer(a), lsp_types.LspParams) ->
    #(lsp_types.LspServer(a), lsp_types.LspParams)

pub fn start(server: lsp_types.LspServer(a), handler_func) {
  let assert Ok(subject) = actor.start(server, handler_func)
  process.start(fn() { read_process(subject) }, True)
}

pub fn send_message(msg: lsp_types.LspMessage) {
  msg
  |> encoder.encode_lsp_message
  |> json.to_string
  |> create_message
  |> io.println
}

// TODO: Move whole message reading/sending into own file
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

// TODO: 
// - Split into smaller functions
// - Move into internal/decoder
fn parse_message(message: String) -> Result(lsp_types.LspMessage, error.Error) {
  use decoded_message <- result.try(decoder.decode_lsp_message(message))
  case decoded_message {
    RpcNotification(method: method) ->
      Ok(lsp_types.LspNotification(method, params: None))

    RpcRequest(id: id, method: method, params: params) ->
      result.try(parse_request_params(method, params), fn(parsed_params) {
        Ok(lsp_types.LspRequest(id: id, method: method, params: parsed_params))
      })

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
    "initialize" ->
      decoder.decode_initalize_params(params)
      |> result.map(Some)
    "textDocument/" <> sub_method -> parse_document_method(sub_method, params)
    _ -> Error(error.method_not_found("Method '" <> method <> "' not found"))
  }
}

fn parse_document_method(
  sub_method: String,
  params: dynamic.Dynamic,
) -> Result(Option(lsp_types.LspParams), error.Error) {
  case sub_method {
    "hover" ->
      decoder.decode_hover_params(params)
      |> result.map(Some)
    "completion" ->
      decoder.decode_completion_params(params)
      |> result.map(Some)
    _ ->
      Error(error.method_not_found(
        "Method 'textDocument/" <> sub_method <> "' not found",
      ))
  }
}

pub fn read_lsp_message() -> Result(lsp_types.LspMessage, error.Error) {
  use message <- result.try(read_rpc_message())
  use lsp_message <- result.try(parse_message(message))
  Ok(lsp_message)
}
