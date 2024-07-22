import error
import gleam/json
import lsp/lsp_types.{type CompletionItem, CompletionItem}
import lsp/server_capabilities as server
import gleam/option.{None, Some}

// ============================== SERVER ENCODER ==============================
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
    #("completionItem", json.nullable(options.resolve_provider, json.bool)),
  ])
}

pub fn encode_server_completion_item(
  item: server.ServerCompletionItem,
) -> json.Json {
  json.object([
    #("labelDetailSupport", json.nullable(item.label_detail_support, json.bool)),
  ])
}

pub fn encode_completion_list(list: lsp_types.CompletionList) -> json.Json {
  json.object([
    #("isIncomplete", json.bool(list.is_incomplete)),
    #("items", json.array(from: list.items, of: encode_completion_item)),
  ])
}

pub fn encode_completion_item(item: lsp_types.CompletionItem) -> json.Json {
  json.object([
    #("label", json.string(item.label)),
    #("kind", json.nullable(from: item.kind, of: json.int)),
    #(
      "documentation",
      json.nullable(from: item.documentation, of: encode_markup_content),
    ),
    #("deprecated", json.nullable(from: item.deprecated, of: json.bool)),
    #("preselect", json.nullable(from: item.deprecated, of: json.bool)),
    #("insertText", json.null()),
    #(
      "insertTextFormat",
      json.nullable(from: item.insert_text_format, of: json.int),
    ),
  ])
}

// ============================== UNIVERSAL ENCODER ==============================

pub fn encode_markup_content(content: lsp_types.MarkupContent) -> json.Json {
  json.object([
    #(
      "kind",
      json.string(case content.kind {
        lsp_types.PlainText -> "plaintext"
        lsp_types.Markdown -> "markdown"
      }),
    ),
    #("value", json.string(content.value)),
  ])
}

pub fn encode_lsp_message(msg: lsp_types.LspMessage) -> json.Json {
  let json_rpc = #("jsonrpc", json.string("2.0"))

  case msg {
    lsp_types.LspNotification(method: method, params: params) ->
      json.object([
        #("jsonrpc", json.string("2.0")),
        #("method", json.string(method)),
        #("params", json.nullable(params, encode_params)),
      ])

    lsp_types.LspRequest(id: id, method: method, params: params) ->
      json.object([
        json_rpc,
        #("id", encode_id(id)),
        #("method", json.string(method)),
        #("params", json.nullable(params, encode_params)),
      ])

    lsp_types.LspResponse(id: id, result: res, error: error) ->
      json.object([
        #("id", encode_id(id)),
        #("result", json.nullable(res, encode_result)),
        #("error", json.nullable(error, encode_error)),
      ])
  }
}

pub fn encode_result(res: lsp_types.LspResult) -> json.Json {
  case res {
    lsp_types.HoverResult(contents) ->
      json.object([#("contents", encode_markup_content(contents))])

    lsp_types.CompletionResult(completion_list) ->
      json.object([
        #("isIncomplete", json.bool(completion_list.is_incomplete)),
        #(
          "items",
          json.array(from: completion_list.items, of: encode_completion_item),
        ),
      ])

    lsp_types.InitializeResult(capabilities, server_info) ->
      json.object([
        #("capabilities", encode_server_capabilities(capabilities)),
        #("serverInfo", json.nullable(server_info, encode_server_info)),
      ])
  }
}

pub fn encode_error(error: error.Error) -> json.Json {
  json.object([
    #("code", json.int(error.code)),
    #("message", json.string(error.msg)),
  ])
}

pub fn encode_id(id: lsp_types.LspId) -> json.Json {
  case id {
    lsp_types.String(text) -> json.string(text)
    lsp_types.Integer(number) -> json.int(number)
  }
}

pub fn encode_params(_params: lsp_types.LspParams) -> json.Json {
  todo as "encoding params is not yet implemented"
}

pub fn encode_server_info(server_info: lsp_types.ServerInfo) -> json.Json {
  json.object([
    #("name", json.string(server_info.name)),
    #("version", json.string(server_info.version)),
  ])
}

