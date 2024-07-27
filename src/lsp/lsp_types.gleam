import error
import gleam/dict
import gleam/option.{type Option, None, Some}
import lsp/client_capabilities
import lsp/server_capabilities

pub type LspEvent {
  LspReceived(LspMessage)
}

pub type LspEventHandler(a) =
  fn(LspServer(a), LspId, LspParams) -> #(LspServer(a), LspMessage)

// TODO: Make LspServer opaque -> only allow construction from the
// new_from_init
pub type LspServer(a) {
  LspServer(
    root_path: String,
    root_uri: String,
    server_caps: server_capabilities.ServerCapabilities,
    client_caps: client_capabilities.ClientCapabilities,
    server_info: ServerInfo,
    state: a,
    handler: Option(dict.Dict(String, LspEventHandler(a))),
  )
}

/// Constructs an [LspServer]
pub fn new_server(
  root_path: String,
  root_uri: String,
  server_caps: server_capabilities.ServerCapabilities,
  client_caps: client_capabilities.ClientCapabilities,
  initial_state: a,
) -> LspServer(a) {
  LspServer(
    root_path: root_path,
    root_uri: root_uri,
    server_caps: server_caps,
    client_caps: client_caps,
    server_info: ServerInfo("graph_lsp", "deez_nuts"),
    state: initial_state,
    handler: None,
  )
}

pub type ServerInfo {
  ServerInfo(name: String, version: String)
}

pub type LspId {
  String(String)
  Integer(Int)
}

pub type ClientInfo {
  ClientInfo(name: String, version: Option(String))
}

pub type MarkupContent {
  /// The MarkupContent literal represents a string value which content can be
  /// displayed in different formats (`MarkupKind` -> Either `PlainText` or
  /// `Markdown`).
  MarkupContent(kind: MarkupKind, value: String)
}

pub type MarkupKind {
  PlainText
  Markdown
}

pub type TextDocumentIdentifier {
  TextDocumentIdentifier(uri: String)
}

pub type Position {
  Position(line: Int, character: Int)
}

// TODO
pub type TextEdit {
  TextEdit
}

/// COMPLETION ==============================
pub type CompletionList {
  CompletionList(
    /// List is not complete: further typing should result in recomputing the
    /// list
    is_incomplete: Bool,
    items: List(CompletionItem),
  )
}

pub type CompletionTriggerKind =
  Int

pub type CompletionContext {
  CompletionContext(
    trigger_kind: CompletionTriggerKind,
    trigger_character: Option(String),
  )
}

pub type InserTextFormat =
  Int

/// link: https://microsoft.github.io/language-server-protocol/specifications/specification-3-14/#completionItem
pub type CompletionItem {
  CompletionItem(
    /// Text that is shown and inserted on selection
    label: String,
    kind: Option(Int),
    detail: Option(String),
    documentation: Option(MarkupContent),
    deprecated: Option(Bool),
    preselect: Option(Bool),
    insert_text_format: Option(InserTextFormat),
    text_edit: Option(TextEdit),
  )
}

/// Params for the LspMethods
pub type LspParams {
  /// HoverParams
  /// **Fields**
  /// `* text_document - File name of request`
  /// `* position - #(Row, Col) of location
  HoverParams(
    /// Text document URI
    text_document: TextDocumentIdentifier,
    position: Position,
  )

  /// CompletionParams
  CompletionParams(
    text_document: TextDocumentIdentifier,
    completion_context: Option(CompletionContext),
  )

  /// Initialization params
  InitializeParams(
    process_id: Option(Int),
    client_info: Option(ClientInfo),
    locale: Option(String),
    root_path: Option(String),
    // initialization_options: Option(dynamic.Dynamic),
    capabilities: client_capabilities.ClientCapabilities,
  )
}

pub type LspResult {
  HoverResult(contents: MarkupContent)
  CompletionResult(completion_list: CompletionList)
  InitializeResult(
    capabilities: server_capabilities.ServerCapabilities,
    server_info: Option(ServerInfo),
  )
}

pub type LspMessage {
  LspNotification(method: String, params: Option(LspParams))
  LspRequest(id: LspId, method: String, params: Option(LspParams))
  LspResponse(id: LspId, result: Option(LspResult), error: Option(error.Error))
}

// ============================== BUILDER ==============================
/// Creates a new [CompletionItem]
pub fn new_ok_response(id: LspId, res: LspResult) -> LspMessage {
  LspResponse(id, Some(res), None)
}

pub fn new_err_response(id: LspId, err: error.Error) -> LspMessage {
  LspResponse(id, None, Some(err))
}
