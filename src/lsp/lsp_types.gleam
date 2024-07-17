import error
import gleam/option.{type Option}
import lsp/client_capabilities
import lsp/server_capabilities

pub opaque type LspConfig {
  LspConfig(
    root_path: Option(String),
    root_uri: Option(String),
    capabilities: server_capabilities.ServerCapabilities,
  )
}

// TODO: Make LspServer opaque -> only allow construction from the
// new_from_init
pub type LspServer {
  LspServer(
    root_path: String,
    root_uri: String,
    server_caps: server_capabilities.ServerCapabilities,
    client_caps: client_capabilities.ClientCapabilities,
    server_info: ServerInfo,
  )
}

/// Constructs an [LspServer]
pub fn new_server(
  root_path: String,
  root_uri: String,
  server_caps: server_capabilities.ServerCapabilities,
  client_caps: client_capabilities.ClientCapabilities,
) -> LspServer {
  LspServer(
    root_path: root_path,
    root_uri: root_uri,
    server_caps: server_caps,
    client_caps: client_caps,
    server_info: ServerInfo("graph_lsp", "deez_nuts"),
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
}

pub type LspResult {
  HoverResult(value: String)
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

pub type Notification {
  Initialized(method: String, params: Option(LspParams))
}
