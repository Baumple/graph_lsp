import gleam/list
import gleam/pair
import gleeunit/should
import internal/parser/parser

pub fn parser_should_return_token_test() {
  let data = "A --> |23| B"
  parser.new_lexer(data)
  |> parser.next_token
  |> pair.first
  |> should.be_some
  |> should.equal(parser.Ident(text: "A"))
}

pub fn tokens_to_list_test() {
  let data = "ABB --> |23| BUS"
  parser.new_lexer(data)
  |> parser.tokens_to_list
  |> should.equal([
    parser.Ident(text: "ABB"),
    parser.Arrow(text: "-->"),
    parser.Bar(text: "|"),
    parser.Number(text: "23", value: 23),
    parser.Bar(text: "|"),
    parser.Ident(text: "BUS"),
  ])
}

pub fn skip_whitespace_test() {
  let t = "       aa    b ccc d"
  let lexer = parser.new_lexer(t)
  parser.skip_whitespace(lexer)
  |> fn(a: parser.Lexer) { a.data }
  |> should.equal("aa    b ccc d")
}

pub fn is_num_test() {
  let tests = [
    #("1", True),
    #("2", True),
    #("345", True),
    #("43e", False),
    #("e", False),
    #("A", False),
  ]
  list.each(tests, fn(t) { parser.is_num(t.0) |> should.equal(t.1) })
}

pub fn is_special_test() {
  let tests = [#("-", True), #(">", True), #(" ", False)]

  list.each(tests, fn(t) { parser.is_special(t.0) |> should.equal(t.1) })
}

pub fn is_alpha_test() {
  let tests = [#("a", True), #("d", True), #(".", False), #("-", False)]

  list.each(tests, fn(t) { parser.is_alpha(t.0) |> should.equal(t.1) })
}
