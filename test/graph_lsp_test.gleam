import decoder/lsp_decoder
import gleam/dynamic
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import graph_lsp
import simplifile

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn count_curly_braces_test() {
  let counter = 0
  let data = "{{{{dasdas{dasdasd{dasdas}}}}}}"
  string.to_graphemes(data)
  |> list.scan(from: counter, with: fn(acc, graph) {
    case graph {
      "{" -> acc + 1
      "}" -> acc - 1
      _ -> acc
    }
  })
  |> list.last
  |> result.unwrap(or: -1)
  |> should.equal(0)

  let counter = 2
  let data = "{{dasdasdas}}}}"
  string.to_graphemes(data)
  |> list.scan(from: counter, with: fn(acc, graph) {
    case graph {
      "{" -> acc + 1
      "}" -> acc - 1
      _ -> acc
    }
  })
  |> list.last
  |> result.unwrap(or: -1)
  |> should.equal(0)
}

pub fn parse_content_length_test() {
  let parse = graph_lsp.parse_content_length
  parse("Content-Length: 100\n")
  |> should.equal(option.Some(100))

  parse("Content-Length")
  |> should.be_none

  parse("")
  |> should.be_none
}

pub type JsonTest {
  JsonTest(hello: Hello)
}

pub fn decode_json_test(json) -> Result(JsonTest, List(dynamic.DecodeError)) {
  dynamic.decode1(JsonTest, dynamic.field("hello", decode_hello))(json)
}

pub type Hello {
  Hello(values: List(Int))
}

fn decode_hello(hello) -> Result(Hello, List(dynamic.DecodeError)) {
  dynamic.decode1(Hello, dynamic.field("val", dynamic.list(dynamic.int)))(hello)
}

pub fn decode_init_params_test() {
  let json =
    simplifile.read("test/init.json")
    |> should.be_ok
  let assert Ok(_) =
    json.decode(from: json, using: lsp_decoder.decode_init_params)
  Nil
}

import encoder/lsp_encoder
import lsp/lsp
import lsp/lsp_types

pub fn encode_init_reponse_test() {
  let server =
    lsp.new_server(
      root_path: "foo",
      root_uri: "bar",
      capabilities: lsp_types.Capabilities(lsp_types.TextDocument(
        lsp_types.TextDocumentCompletion(
          lsp_types.CompletionItemKind([1]),
          lsp_types.CompletionItem(True, True),
        ),
        lsp_types.TextDocumentHover(["plain"]),
      )),
    )
  let _ =
    json.object([
      lsp_encoder.encode_capabilities(server.capabilities),
      lsp_encoder.encode_server_info(server.server_info),
    ])
    |> json.to_string
  Nil
}

pub fn decode_init_test() {
  let assert Ok(json) = simplifile.read("test/init.json")
  json.decode(json, lsp_decoder.decode_init_params)
  |> should.be_ok()
}
