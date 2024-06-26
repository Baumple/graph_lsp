import gleam/json
import lsp_types as lsp

pub fn encode_server_info(server_info: lsp.ServerInfo) -> #(String, json.Json) {
  #(
    "serverInfo",
    json.object([
      #("name", json.string(server_info.name)),
      #("version", json.string(server_info.version)),
    ]),
  )
}

pub fn encode_capabilities(
  capabilities: lsp.Capabilities,
) -> #(String, json.Json) {
  #(
    "capabilities",
    json.object([encode_text_document_capability(capabilities.text_document)]),
  )
}

fn encode_text_document_capability(
  td_capability: lsp.TextDocument,
) -> #(String, json.Json) {
  #(
    "textDocument",
    json.object([
      encode_text_document_completion(td_capability.completion),
      encode_text_document_hover(td_capability.hover),
    ]),
  )
}

fn encode_text_document_hover(
  hover: lsp.TextDocumentHover,
) -> #(String, json.Json) {
  #(
    "hover",
    json.object([
      #(
        "contentFormat",
        json.array(from: hover.content_format, of: json.string),
      ),
    ]),
  )
}

fn encode_text_document_completion(
  completion: lsp.TextDocumentCompletion,
) -> #(String, json.Json) {
  #(
    "completion",
    json.object([
      encode_completion_item_kind(completion.completion_item_kind),
      encode_completion_item(completion.completion_item),
    ]),
  )
}

fn encode_completion_item(
  completion_item: lsp.CompletionItem,
) -> #(String, json.Json) {
  #(
    "completionItem",
    json.object([
      #("snippetSupport", json.bool(completion_item.snippet_support)),
      #(
        "commitCharactersSupport",
        json.bool(completion_item.commit_characters_support),
      ),
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
