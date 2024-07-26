import gleam/option.{type Option, Some, None}

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

/// Creates [ServerCapabilities] with all fields set to
/// None
pub fn new_server_capabilities() -> ServerCapabilities {
  ServerCapabilities(
    completion_provider: None,
    document_symbol_provider: None,
    hover_provider: None,
    text_document_sync: None,
  )
}

/// Updates the [hover_provider] field on
/// [ServerCapabilities] record
pub fn set_hover_provider(
  capabilities: ServerCapabilities,
  hover_provider: Bool,
) -> ServerCapabilities {
  ServerCapabilities(..capabilities, hover_provider: Some(hover_provider))
}

pub fn set_completion_provider(
  capabilities: ServerCapabilities,
  completion_options: CompletionOptions,
) -> ServerCapabilities {
  ServerCapabilities(
    ..capabilities,
    completion_provider: Some(completion_options),
  )
}
