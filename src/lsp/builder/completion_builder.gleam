import lsp/lsp_types.{
  type CompletionItem, type MarkupContent, CompletionItem, MarkupContent,
}
import gleam/option.{None, Some}

/// Creates a new [CompletionItem]
pub fn new(label: String) -> CompletionItem {
  CompletionItem(label, None, None, None, None, None, None, None)
}

/// Set [CompletionItem] deprecated
pub fn set_deprecated(
  comp_item: CompletionItem,
  deprecated: Bool,
) -> CompletionItem {
  CompletionItem(..comp_item, deprecated: Some(deprecated))
}

/// Set [CompletionItem] documentation
pub fn set_documentation(
  comp_item,
  documentation: MarkupContent,
) -> CompletionItem {
  CompletionItem(..comp_item, documentation: Some(documentation))
}

pub fn set_documentation_text(
  comp_item,
  documentation: String,
) -> CompletionItem {
  CompletionItem(
    ..comp_item,
    documentation: Some(lsp_types.MarkupContent(
      kind: lsp_types.PlainText,
      value: "```gleam\n" <> documentation <> "\n```",
    )),
  )
}
