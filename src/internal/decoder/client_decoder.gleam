import gleam/dynamic
import lsp/client_capabilities as client
import lsp/lsp_types

pub fn decode_client_info(
  client_info,
) -> Result(lsp_types.ClientInfo, dynamic.DecodeErrors) {
  dynamic.decode2(
    lsp_types.ClientInfo,
    dynamic.field("name", dynamic.string),
    dynamic.optional_field("version", dynamic.string),
  )(client_info)
}

pub fn decode_client_capabilities(
  capabilities,
) -> Result(client.ClientCapabilities, dynamic.DecodeErrors) {
  capabilities
  |> dynamic.decode1(
    client.ClientCapabilities,
    dynamic.optional_field("textDocument", decode_text_document_capabilities),
  )
}

pub fn decode_text_document_capabilities(
  capabilities,
) -> Result(client.TextDocumentClientCapabilities, dynamic.DecodeErrors) {
  capabilities
  |> dynamic.decode2(
    client.TextDocumentClientCapabilities,
    dynamic.optional_field(
      "synchronization",
      decode_text_document_sync_capabilities,
    ),
    dynamic.optional_field("completion", decode_completion_client_capabilities),
  )
}

pub fn decode_text_document_sync_capabilities(
  sync_cap,
) -> Result(client.TextDocumentSyncClientCapabilities, dynamic.DecodeErrors) {
  sync_cap
  |> dynamic.decode4(
    client.TextDocumentSyncClientCapabilities,
    dynamic.optional_field("dynamicRegistration", dynamic.bool),
    dynamic.optional_field("willSave", dynamic.bool),
    dynamic.optional_field("willSaveWaitUntil", dynamic.bool),
    dynamic.optional_field("didSave", dynamic.bool),
  )
}

pub fn decode_completion_client_capabilities(
  completion,
) -> Result(client.CompletionClientCapabilities, dynamic.DecodeErrors) {
  completion
  |> dynamic.decode2(
    client.CompletionClientCapabilites,
    dynamic.optional_field("completionItem", decode_completion_item),
    dynamic.optional_field("completionItemKind", decode_completion_item_kind),
  )
}

pub fn decode_completion_item(
  comp_item,
) -> Result(client.CompletionItem, dynamic.DecodeErrors) {
  comp_item
  |> dynamic.decode2(
    client.CompletionItem,
    dynamic.optional_field("snippetSupport", dynamic.bool),
    dynamic.optional_field("commitCharactersSupport", dynamic.bool),
  )
}

pub fn decode_completion_item_kind(
  comp_kind,
) -> Result(client.CompletionItemKind, dynamic.DecodeErrors) {
  comp_kind
  |> dynamic.decode1(
    client.CompletionItemKind,
    dynamic.optional_field("valueSet", dynamic.list(dynamic.int)),
  )
}
