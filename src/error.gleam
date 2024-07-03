import gleam/dynamic
import gleam/json

const parse_error_code = -32_700

const method_not_found_code = -32_601

const initialize_not_received_code = -32_000

pub type Error {
  DecodeRpcError(code: Int, msg: String, json.DecodeError)
  DecodeParamsError(code: Int, msg: String, err: dynamic.DecodeErrors)

  MissingParameters(code: Int, msg: String)

  InitializeNotReceived(code: Int, msg: String)
  MethodNotFound(code: Int, msg: String)
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
