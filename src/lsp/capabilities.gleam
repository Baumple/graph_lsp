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
