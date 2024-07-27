import error
import gleam/erlang/process
import gleam/io as gleam_io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import internal/lsp_io
import lsp/lsp_types.{type LspEventHandler}
import lsp/server_capabilities
import pprint

pub opaque type ServerConfig(a) {
  ServerConfig(
    initial_state: a,
    server_caps: server_capabilities.ServerCapabilities,
    hover_handler: Option(LspEventHandler(a)),
    completion_handler: Option(LspEventHandler(a)),
    did_save_handler: Option(LspEventHandler(a)),
  )
}

pub fn new_server(state initial_state: a) -> ServerConfig(a) {
  ServerConfig(
    initial_state,
    server_capabilities.new_server_capabilities(),
    None,
    None,
    None,
  )
}

/// Registers an event handler for the textDocument/hover lsp event
/// Also updates the [server_capabilities.ServerCapabilities] record
/// appropriately
pub fn set_hover_handler(
  config: ServerConfig(a),
  handler: LspEventHandler(a),
) -> ServerConfig(a) {
  let capabilities =
    server_capabilities.ServerCapabilities(
      ..config.server_caps,
      hover_provider: Some(True),
    )
  ServerConfig(
    ..config,
    hover_handler: Some(handler),
    server_caps: capabilities,
  )
}

/// Register a handler for the "textDocument/completion" event.
/// Also updates the [server_capabilities.ServerCapabilities] record
/// appropriately
pub fn set_completion_handler(
  config: ServerConfig(a),
  handler: LspEventHandler(a),
  options: server_capabilities.CompletionOptions,
) -> ServerConfig(a) {
  let capabilities =
    server_capabilities.ServerCapabilities(
      ..config.server_caps,
      completion_provider: Some(options),
    )
  ServerConfig(
    ..config,
    completion_handler: Some(handler),
    server_caps: capabilities,
  )
}

/// Set a handler for the didSave event
/// Also updates the [server_capabilities.ServerCapabilities] record
/// appropriately
pub fn set_did_save_handler(
  config: ServerConfig(a),
  handler: LspEventHandler(a),
) -> ServerConfig(a) {
  ServerConfig(..config, did_save_handler: Some(handler))
}

/// Does the necessarry work to create an [LspServer] and then returns either
/// the LspServer or an Error containing more information. 
pub fn create_server(
  initial_state: a,
  capabilities: server_capabilities.ServerCapabilities,
) -> Result(lsp_types.LspServer(a), error.Error) {
  lsp_io.read_lsp_message()
  |> server_from_init(initial_state, capabilities)
}

/// Accepts a [Result] of an [lsp_types.LspMessage] and a record of
/// [server_capabilities.ServerCapabilities] and then tries to construct an
/// [lsp_types.LspServer]
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
      |> lsp_io.send_message

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

/// Checks for input in stdin, parses it and sends a message to the evaluator
/// actor if it could parse succesful 
fn read_process(server_subject: process.Subject(lsp_types.LspEvent)) {
  case lsp_io.read_lsp_message() {
    Ok(msg) -> process.send(server_subject, lsp_types.LspReceived(Ok(msg)))
    Error(err) ->
      gleam_io.println_error("Some error occured: " <> pprint.format(err))
  }
  read_process(server_subject)
}

// /// Waits for incoming [LspEvent]s and maps the provided
// /// [LspEventHandler] to them
// fn main_actor(
//   msg: lsp_types.LspEvent,
//   server: lsp_types.LspServer(a),
// ) -> actor.Next(lsp_types.LspEvent, lsp_types.LspServer(a)) {
//   let lsp_types.LspReceived(msg) = msg
//   gleam_io.println_error("Received msg")
//   case msg {
//     lsp_types.LspRequest(
//       id: id,
//       method: "textDocument/hover",
//       params: Some(params),
//     ) -> {
//       gleam_io.println_error("hover")
//       let assert Some(handlers) = server.handler
//       let _ =
//         handlers
//         |> dict.get("hover")
//         |> result.map(fn(handler) {
//           let #(_, resp) = handler(server, id, params)
//           send_message(resp)
//         })
//       Nil
//     }
//     _ -> Nil
//   }
//   actor.continue(server)
// }
// 
// 
// pub fn start_with_handlers(config config: ServerConfig(a)) {
//   let assert Ok(server) =
//     create_server(config.initial_state, config.server_caps)
//   let handler = case config.hover_handler {
//     Some(hover_handler) -> dict.new() |> dict.insert("hover", hover_handler)
//     None -> dict.new()
//   }
// 
//   let server = lsp_types.LspServer(..server, handler: Some(handler))
//   let assert Ok(main_actor) = actor.start(server, main_actor)
//   process.start(fn() { read_process(main_actor) }, False)
// }

pub fn start_with_main(server: lsp_types.LspServer(a), main_handler) {
  let assert Ok(subject) = actor.start(server, main_handler)
  process.start(fn() { read_process(subject) }, True)
}

pub fn send_message(msg: lsp_types.LspMessage) {
  lsp_io.send_message(msg)
}

/// Updates the server state. Useful when piping.
pub fn update_server_state(
  state: a,
  server: lsp_types.LspServer(a),
) -> lsp_types.LspServer(a) {
  lsp_types.LspServer(..server, state: state)
}
