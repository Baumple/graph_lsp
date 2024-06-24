import gleam/dynamic
import lsp_types as lsp

pub fn decode_initialize_params(params) {
  dynamic.decode3(
    lsp.InitializeMethod,
    dynamic.field("rootPath", dynamic.string),
    dynamic.field("rootUri", dynamic.string),
    dynamic.field("capabilities", decode_capabilities),
  )(params)
}

fn decode_capabilities(
  init_params,
) -> Result(lsp.Capabilities, List(dynamic.DecodeError)) {
  dynamic.decode1(lsp.Capabilities, decode_capability)(init_params)
}

fn decode_capability(capability) {
  dynamic.any([
    dynamic.decode1(
      lsp.TextDocument,
      dynamic.field(
        "textDocument",
        dynamic.list(decode_text_document_capabilities),
      ),
    ),
    dynamic.decode1(lsp.Any, dynamic.dynamic),
  ])(capability)
}

fn decode_text_document_capabilities(td_capabilities) {

}

fn decode_text_document_capability(td_capability) {
  dynamic.any([
    dynamic.decode2(
      lsp.Completion,
      dynamic.field("completionItem", decode_completion_item),
      dynamic.field("completionItemKind", decode_completion_item_kind),
    ),
    dynamic.decode2(
      lsp.Hover,
      dynamic.field("contentFormat", dynamic.list(dynamic.string)),
      dynamic.field("dynamicRegistration", dynamic.bool),
    ),
  ])(td_capability)
}

fn decode_completion_item(completion_item) {
  dynamic.decode3(
    lsp.CompletionItem,
    dynamic.field("commitCharactersSupport", of: dynamic.bool),
    dynamic.field("documentationFormat", of: dynamic.list(dynamic.string)),
    dynamic.field("snippetSupport", of: dynamic.bool),
  )(completion_item)
}

fn decode_completion_item_kind(completion_item_kind) {
  dynamic.decode1(
    lsp.CompletionItemKind,
    dynamic.field("completionItemKind", of: dynamic.list(dynamic.int)),
  )(completion_item_kind)
}
