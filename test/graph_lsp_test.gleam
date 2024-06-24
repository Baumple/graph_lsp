import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

import gleam/list
import gleam/result
import gleam/string

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

import gleam/option
import graph_lsp

pub fn parse_content_length_test() {
  let parse = graph_lsp.parse_content_length
  parse("Content-Length: 100\n")
  |> should.equal(option.Some(100))

  parse("Content-Length")
  |> should.be_none

  parse("")
  |> should.be_none
}

