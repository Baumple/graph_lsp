import gleam/option.{type Option}

pub type SafeOptions {
  SafeOptions
  Bool(Bool)
}

// TODO:
// Continue:
// https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#initialize
pub type ServerCapabilities {
  ServerCapabilities(
    text_document_sync: Option(TextDocumentSyncOptions),
    completion_provider: Option(CompletionOptions),
    // TODO: HoverOptions instead of plain bool
    hover_provider: Option(Bool),
    document_symbol_provider: Option(Bool),
    // TODO: diagnostic_provider: Option(DiagnosticOptions),
  )
}

pub type CompletionOptions {
  CompletionOptions(
    trigger_characters: Option(List(String)),
    completion_item: Option(ServerCompletionItem),
  )
}

pub type ServerCompletionItem {
  ServerCompletionItem(label_detail_support: Option(Bool))
}

pub type TextDocumentSyncOptions {
  TextDocumentSyncOption(
    open_close: Option(Bool),
    change: Option(Bool),
    will_save: Option(Bool),
    will_save_wait_until: Option(Bool),
    save: Option(SafeOptions),
  )
}
