import error
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import internal/decoder
import internal/encoder
import internal/rpc_types.{RpcNotification, RpcRequest, RpcResponse}
import lsp/lsp_types

/// IO devices for erlang
pub type StandardIO {
  StandardIO
}

/// get `count` chars fom io_device with given `prompt` and return input
@external(erlang, "io", "get_chars")
fn get_chars(io_device: StandardIO, prompt: String, count: Int) -> String

/// `Prompt` the user for input and read entire line from stdin
@external(erlang, "io", "get_line")
fn prompt_input(prompt: String) -> String

/// Read `count` bytes from stdin
fn get_bytes(count: Int) -> String {
  get_chars(StandardIO, "", count)
}

/// Read an entire line from stdin (no prompt)
pub fn get_line() -> String {
  prompt_input("")
}

// rpc header looks as follows:
// Content-Length: xxxx\r\n
// \r\n
// ...
/// Reads a jsonrpc message from stdin and returns it on success.
fn read_rpc_message() -> Result(String, error.Error) {
  let error = error.parse_error("Could not parse Content-Length in rpc header")
  use length <- result.try(
    get_line()
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
  get_bytes(2)
  Ok(get_bytes(length))
}

// TODO: 
// - Split into smaller functions
// - Move into internal/decoder
/// Parses a jsonrpc string and returns a lsp_types.LspMessage type
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

/// Handles everything from reading to parsing and returns the read
/// [lsp_types.LspMessage]
pub fn read_lsp_message() -> Result(lsp_types.LspMessage, error.Error) {
  use message <- result.try(read_rpc_message())
  use lsp_message <- result.try(parse_message(message))
  Ok(lsp_message)
}

// TODO: Move whole message reading/sending into own file
fn create_message(json) {
  "Content-Length: " <> int.to_string(string.length(json)) <> "\r\n\r\n" <> json
}

pub fn send_message(msg: lsp_types.LspMessage) {
  msg
  |> encoder.encode_lsp_message
  |> json.to_string
  |> create_message
  |> io.println
}
