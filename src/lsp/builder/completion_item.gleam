import gleam/option.{None, Some}
import lsp/lsp_types.{
  type CompletionItem, type MarkupContent, CompletionItem, MarkupContent,
  PlainText,
}

pub fn new_completion_item(label: String) -> CompletionItem {
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
  comp_item: CompletionItem,
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
    documentation: Some(MarkupContent(
      kind: PlainText,
      value: "```gleam\n" <> documentation <> "\n```",
    )),
  )
}
