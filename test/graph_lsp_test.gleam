import gleam/list
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
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
