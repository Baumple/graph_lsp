import gleam/dynamic
import gleam/json

const parse_error = -32_700

const method_not_found = -32_601

const initialize_not_received = -32_000

pub type Error {
  DecodeError(code: Int, error: DecodeError)
  MethodError(code: Int, error: MethodError)
}

pub type DecodeError {
  DecodeMessageError(msg: String, error: json.DecodeError)
  DecodeParamsError(msg: String, error: dynamic.DecodeErrors)
}

pub type MethodError {
  InitializeNotReceived(code: Int, msg: String)
  UnimplementedMethod(code: Int, msg: String)
}

// TODO: Maybe give received message as parameter
pub fn init_not_received() -> MethodError {
  InitializeNotReceived(
    code: initialize_not_received,
    msg: "Initialize message was not received",
  )
}
