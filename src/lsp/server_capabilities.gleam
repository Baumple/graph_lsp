import gleam/option.{type Option}

pub type SaveOptions {
  SaveOptions
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
  )
  // TODO: diagnostic_provider: Option(DiagnosticOptions),
}

pub type CompletionOptions {
  CompletionOptions(
    /// The server provides support to resolve additional information for a
    /// completion item
    resolve_provider: Option(Bool),
    /// Characters that trigger completion automatically
    trigger_characters: Option(List(String)),
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
    save: Option(SaveOptions),
  )
}
