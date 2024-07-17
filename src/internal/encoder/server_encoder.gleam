import gleam/json
import lsp/server_capabilities as server

pub fn encode_server_capabilities(caps: server.ServerCapabilities) -> json.Json {
  json.object([
    #(
      "textDocumentSync",
      json.nullable(caps.text_document_sync, encode_text_document_sync_options),
    ),
    #(
      "completionProvider",
      json.nullable(caps.completion_provider, encode_completion_options),
    ),
    #("hoverProvider", json.nullable(caps.hover_provider, json.bool)),
    #(
      "documentSymbolProvider",
      json.nullable(caps.document_symbol_provider, json.bool),
    ),
  ])
}

pub fn encode_text_document_sync_options(
  so: server.TextDocumentSyncOptions,
) -> json.Json {
  json.object([
    #("openClose", json.nullable(so.open_close, json.bool)),
    #("change", json.nullable(so.change, json.bool)),
    #("willSave", json.nullable(so.will_save, json.bool)),
    #("willSaveWaitUntil", json.nullable(so.will_save_wait_until, json.bool)),
    #("save", json.nullable(so.save, encode_save_options)),
  ])
}

pub fn encode_save_options(so: server.SaveOptions) -> json.Json {
  case so {
    server.SaveOptions -> json.bool(False)
    server.Bool(value) -> json.bool(value)
  }
}

pub fn encode_completion_options(options: server.CompletionOptions) -> json.Json {
  json.object([
    #(
      "triggerCharacters",
      json.nullable(options.trigger_characters, fn(characters) {
        json.array(characters, json.string)
      }),
    ),
    #(
      "completionItem",
      json.nullable(options.completion_item, encode_completion_item),
    ),
  ])
}

pub fn encode_completion_item(item: server.ServerCompletionItem) -> json.Json {
  json.object([
    #("labelDetailSupport", json.nullable(item.label_detail_support, json.bool)),
  ])
}

