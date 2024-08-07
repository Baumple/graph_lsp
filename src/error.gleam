//// Errors
import gleam/dynamic
import gleam/json
import pprint
import simplifile

const parse_error_code = -32_700

const method_not_found_code = -32_601

const initialize_not_received_code = -32_000

const unexpected_method_code = -32_001

const io_error_code = -32_002

const client_error_received_code = -32_003

const invalid_request_code = -32_602

pub type Error {
  DecodeRpcError(code: Int, msg: String, json.DecodeError)
  DecodeParamsError(code: Int, msg: String, err: dynamic.DecodeErrors)

  MissingParameters(code: Int, msg: String)
  InitializeNotReceived(code: Int, msg: String)

  MethodNotFound(code: Int, msg: String)
  UnexpectedMethod(code: Int, msg: String)
  ParseError(code: Int, msg: String)
  InvalidRequest(code: Int, msg: String)

  IOError(code: Int, msg: String, error: simplifile.FileError)

  ClientError(code: Int, msg: String)
}

// TODO: Maybe give received message as parameter
pub fn init_not_received() -> Error {
  InitializeNotReceived(
    code: initialize_not_received_code,
    msg: "Initialize message was not received",
  )
}

pub fn missing_parameters() -> Error {
  MissingParameters(
    parse_error_code,
    "Method expected parameters but found none",
  )
}

pub fn decode_rpc_error(err) -> Error {
  DecodeRpcError(parse_error_code, "Could not parse rpc message", err)
}

pub fn decode_params_error(err: dynamic.DecodeErrors) -> Error {
  DecodeParamsError(
    code: parse_error_code,
    msg: "Could not parse method params",
    err: err,
  )
}

pub fn method_not_found(method: String) -> Error {
  MethodNotFound(method_not_found_code, "Could not find method: " <> method)
}

pub fn unexpected_method(method: String) -> Error {
  UnexpectedMethod(
    unexpected_method_code,
    "Did not expect '" <> method <> "' method",
  )
}

pub fn io_error(msg: String, error: simplifile.FileError) {
  IOError(code: io_error_code, msg: msg, error: error)
}

pub fn parse_error(msg: a) -> Error {
  ParseError(code: parse_error_code, msg: pprint.format(msg))
}

pub fn client_error(msg: a) -> Error {
  ClientError(code: client_error_received_code, msg: pprint.format(msg))
}

pub fn invalid_request(msg: String) -> Error {
  InvalidRequest(code: invalid_request_code, msg: msg)
}
