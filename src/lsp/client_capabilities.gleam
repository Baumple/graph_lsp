import gleam/option.{type Option}

pub type ClientCapabilities {
  ClientCapabilities(text_document: Option(TextDocumentClientCapabilities))
}

pub type TextDocumentClientCapabilities {
  TextDocumentClientCapabilities(
    synchronization: Option(TextDocumentSyncClientCapabilities),
    completion: Option(CompletionClientCapabilities),
  )
}

pub type CompletionClientCapabilities {
  CompletionClientCapabilites(
    completion_item: Option(CompletionItem),
    completion_item_kind: Option(CompletionItemKind),
  )
}

pub type CompletionItemKind {
  CompletionItemKind(value_set: Option(List(Int)))
}

pub type CompletionItem {
  CompletionItem(
    snippet_support: Option(Bool),
    commit_characters_support: Option(Bool),
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
