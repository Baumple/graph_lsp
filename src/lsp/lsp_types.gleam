import internal/rpc/rpc_types
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

pub type LspMessage {
  LspRequest(rpc_request: rpc_types.RpcMessage, method: LspMethod)
  LspResponse(rpc_response: rpc_types.RpcMessage)
}
