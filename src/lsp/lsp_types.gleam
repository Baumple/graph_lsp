import rpc/rpc_types

pub type LspServer {
  LspServer(
    root_path: String,
    root_uri: String,
    capabilities: Capabilities,
    server_info: ServerInfo,
  )
}

pub type ServerInfo {
  ServerInfo(name: String, version: String)
}

/// [LspMethod] hold information about given params
pub type LspMethod {
  InitializeMethod(
    root_path: String,
    root_uri: String,
    capabilities: Capabilities,
  )
  InitializeResult
}

pub type LspMessage(a) {
  LspRequest(rpc_request: rpc_types.RpcMessage, method: LspMethod)
  LspResponse(rpc_response: rpc_types.RpcMessage)
}

pub type Capabilities {
  Capabilities(text_document: TextDocument)
}

pub type TextDocument {
  TextDocument(completion: TextDocumentCompletion, hover: TextDocumentHover)
}

pub type TextDocumentHover {
  TextDocumentHover(content_format: List(String))
}

pub type TextDocumentCompletion {
  TextDocumentCompletion(
    completion_item_kind: CompletionItemKind,
    completion_item: CompletionItem,
  )
}

pub type CompletionItemKind {
  CompletionItemKind(value_set: List(Int))
}

pub type CompletionItem {
  CompletionItem(snippet_support: Bool, commit_characters_support: Bool)
}
