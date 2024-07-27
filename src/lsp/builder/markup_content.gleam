import lsp/lsp_types.{type MarkupContent, Markdown, MarkupContent}

/// Takes a `String` and wraps it in a `MarkupContent` record with the `Markdown`
/// markup type.
pub fn new_markdown(
  language language: String,
  text content: String,
) -> MarkupContent {
  MarkupContent(
    kind: Markdown,
    value: "```" <> language <> "\n" <> content <> "\n```",
  )
}
