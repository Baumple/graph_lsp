import error
import gleam/json
import internal/encoder/server_encoder
import lsp/lsp_types

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
    lsp_types.HoverResult(value) ->
      json.object([#("value", json.string(value))])

    lsp_types.InitializeResult(capabilities, server_info) ->
      json.object([
        #(
          "capabilities",
          server_encoder.encode_server_capabilities(capabilities),
        ),
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
