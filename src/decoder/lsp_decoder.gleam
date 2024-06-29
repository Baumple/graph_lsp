import gleam/dynamic
import lsp/lsp_types

pub fn decode_init_params(params_json) {
  dynamic.decode3(
    lsp_types.InitializeMethod,
    dynamic.field("rootPath", dynamic.string),
    dynamic.field("rootUri", dynamic.string),
    dynamic.field("capabilities", decode_capabilities),
  )(params_json)
}

fn decode_capabilities(capabilities) {
  dynamic.decode1(
    lsp_types.Capabilities,
    dynamic.field("textDocument", decode_text_document_capability),
  )(capabilities)
}

fn decode_text_document_capability(text_document) {
  dynamic.decode2(
    lsp_types.TextDocument,
    dynamic.field("completion", decode_text_document_completion),
    dynamic.field("hover", decode_text_document_hover),
  )(text_document)
}

fn decode_text_document_hover(td_hover) {
  dynamic.decode1(
    lsp_types.TextDocumentHover,
    dynamic.field("contentFormat", dynamic.list(dynamic.string)),
  )(td_hover)
}

fn decode_text_document_completion(completion) {
  dynamic.decode2(
    lsp_types.TextDocumentCompletion,
    dynamic.field("completionItemKind", decode_completion_item_kind),
    dynamic.field("completionItem", decode_completion_item),
  )(completion)
}

fn decode_completion_item_kind(comp_kind) {
  dynamic.decode1(
    lsp_types.CompletionItemKind,
    dynamic.field("valueSet", dynamic.list(dynamic.int)),
  )(comp_kind)
}

fn decode_completion_item(comp_item) {
  dynamic.decode2(
    lsp_types.CompletionItem,
    dynamic.field("snippetSupport", dynamic.bool),
    dynamic.field("commitCharactersSupport", dynamic.bool),
  )(comp_item)
}
