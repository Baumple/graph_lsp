import gleam/option.{type Option}

pub type ClientCapabilities {
  ClientCapabilities(text_document: Option(TextDocumentClientCapabilities))
}

pub type TextDocumentClientCapabilities {
  TextDocumentClientCapabilities(
    synchronization: Option(TextDocumentSyncClientCapabilities),
    completion: Option(CompletionClientCapabilities),
    hover: Option(HoverClientCapabilities),
  )
}

pub type TextDocumentSyncClientCapabilities {
  TextDocumentSyncClientCapabilities(
    dynamic_registration: Option(Bool),
    will_save: Option(Bool),
    will_save_wait_until: Option(Bool),
    did_save: Option(Bool),
  )
}
