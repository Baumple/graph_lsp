import error
import gleam/dynamic
import gleam/option.{type Option}
import lsp/capabilities
import lsp/client_capabilities
import lsp/server_capabilities

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

pub type LspId {
  String(String)
  Integer(Int)
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
    // initialization_options: Option(dynamic.Dynamic),
    capabilities: client_capabilities.ClientCapabilities,
    // trace: dynamic.Dynamic,
    // workspace_folders: Option(List(WorkspaceFolder)),
  )
  Nil
}

pub type LspResult {
  HoverResult(value: String)
  InitializeResult(
    capabilites: server_capabilities.ServerCapabilities,
    server_info: Option(ServerInfo),
  )
}

pub type LspMessage {
  LspNotification(method: String)
  LspRequest(id: Option(LspId), method: String, params: Option(LspParams))
  LspResponse(
    id: Option(LspId),
    result: Option(LspResult),
    error: Option(error.Error),
  )
}

pub type Notification {
  Initialized(method: String, params: Option(LspParams))
}
