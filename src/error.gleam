import gleam/dynamic
import gleam/json

const parse_error = -32_700

const method_not_found = -32_601

const initialize_not_received = -32_000

pub type Error {
  MethodError(code: Int, error: MethodError)
  DecodeMessageError(code: Int, msg: String)
}

pub type MethodError {
  InitializeNotReceived(code: Int, msg: String)
  UnimplementedMethod(code: Int, msg: String)
  DecodeParamsError(code: Int, msg: String)
}

// TODO: Maybe give received message as parameter
pub fn init_not_received() -> MethodError {
  InitializeNotReceived(
    code: initialize_not_received,
    msg: "Initialize message was not received",
  )
}
