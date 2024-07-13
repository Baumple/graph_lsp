import error
import gleam/option.{type Option}
import lsp/capabilities
import lsp/text_document

pub type LspServer {
  LspServer(
    root_path: String,
    root_uri: String,
    capabilities: capabilities.Capabilities,
    server_info: ServerInfo,
  )
}

pub type ServerInfo {
  ServerInfo(name: String, version: String)
}

/// [LspMethod] hold information about given params
pub type LspMethod {
  Initialize(
    name: String,
    root_path: String,
    root_uri: String,
    capabilities: capabilities.Capabilities,
  )
  Initialized(name: String)
  DidSave(name: String, document_ident: text_document.TextDocumentIdentifier)
}

pub fn new_did_save(params: text_document.TextDocumentIdentifier) {
  DidSave(name: "textDocument/didSave", document_ident: params)
}

pub fn new_initialize(
  root_path root_path: String,
  root_uri root_uri: String,
  capabilities capabilities: capabilities.Capabilities,
) -> LspMethod {
  Initialize("initialize", root_path, root_uri, capabilities)
}

pub fn new_initialized() -> LspMethod {
  Initialized("initialized")
}

pub type LspId {
  String(String)
  Integer(Int)
}

pub type LspError {
  LspError(code: Int, message: String, data: Option(error.Error))
}

pub type ClientInfo {
  ClientInfo(name: String, version: Option(String))
}

pub type LspParams {
  HoverParams(
    /// Text document URI
    text_document: String,
    position: #(Int, Int),
  )
  InitializeParams(
    process_id: Option(Int),
    client_info: Option(ClientInfo),
    locale: Option(String),
    root_path: Option(String),
    initialization_options: Option(dynamic.Dynamic),
    capabilities: ClientCapabilities,
    trace: dynamic.Dynamic,
    workspace_folders: Option(List(WorkspaceFolder))
  )
}

pub type LspResult {
  HoverResult(value: String)
}

pub type Message {
  Request(id: LspId, method: String, params: Option(LspParams))
  Notification(method: String, params: Option(LspParams))
  Response(
    id: Option(LspId),
    result: Option(LspResult),
    error: Option(LspError),
  )
}
