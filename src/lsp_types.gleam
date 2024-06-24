import gleam/dynamic
import rpc_types

pub type LspServer {
  LspServer(root_path: String, root_uri: String, capabilities: Capabilities)
}

/// [LspMethod] hold information about given params
pub type LspMethod {
  InitializeMethod(
    root_path: String,
    root_uri: String,
    capabilities: Capabilities,
  )
}

pub type LspMessage {
  LspRequest(rpc_request: rpc_types.RpcRequest, method: LspMethod)
}

pub type Capabilities {
  Capabilities(text_document: Capability)
}

pub type Capability {
  TextDocument(td_capabilities: TextDocumentCapability)
  Any(dynamic.Dynamic)
}

pub type TextDocumentCapabilities {
  TextDocumentCapabilities(
    completion: TextDocumentCapability,
    hover: TextDocumentCapability,
  )
}

pub type TextDocumentCapability {
  Completion(
    completion_item: CompletionItem,
    completion_item_kind: CompletionItemKind,
  )
  Hover(content_format: List(String), dynamic_registration: Bool)
}

pub type CompletionItem {
  CompletionItem(
    commit_characters_support: Bool,
    documentation_format: List(String),
    snippet_support: Bool,
  )
}

pub type CompletionItemKind {
  CompletionItemKind(value_set: List(Int))
}

pub type LspError {
  RpcError(msg: String, rpc_error: rpc_types.ErrorCode)
}
