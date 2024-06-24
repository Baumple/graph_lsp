import gleam/json
import gleam/list
import lsp_types as lsp

pub fn encode_capabilities(
  capabilities: List(lsp.Capability),
) -> #(String, json.Json) {
  #("capabilities", json.object(list.map(capabilities, encode_capability)))
}

fn encode_capability(capability: lsp.Capability) -> #(String, json.Json) {
  case capability {
    lsp.TextDocument(td_capabilities) -> #(
      "textDocument",
      json.object(td_capabilities |> list.map(encode_text_document_capability)),
    )
    lsp.Any(..) -> panic
  }
}

fn encode_text_document_capability(
  capability: lsp.TextDocumentCapability,
) -> #(String, json.Json) {
  case capability {
    lsp.Completion(completion_item, completion_item_kind) -> #(
      "completion",
      json.object([
        encode_completion_item(completion_item),
        encode_completion_item_kind(completion_item_kind),
      ]),
    )
    lsp.Hover(content_format, dynamic_registration) -> #(
      "hover",
      json.object([
        #("contentFormat", json.array(from: content_format, of: json.string)),
        #("dynamicRegistration", json.bool(dynamic_registration)),
      ]),
    )
  }
}

fn encode_completion_item(
  completion_item: lsp.CompletionItem,
) -> #(String, json.Json) {
  #(
    "completionItem",
    json.object([
      #(
        "commitCharactersSupport",
        json.bool(completion_item.commit_characters_support),
      ),
      #(
        "documentation_format",
        json.array(from: completion_item.documentation_format, of: json.string),
      ),
      #("snippet_support", json.bool(completion_item.snippet_support)),
    ]),
  )
}

fn encode_completion_item_kind(
  item_kind: lsp.CompletionItemKind,
) -> #(String, json.Json) {
  #(
    "completionItemKind",
    json.object([
      #("valueSet", json.array(from: item_kind.value_set, of: json.int)),
    ]),
  )
}
