import gleeunit/should
import internal/parser/parser

pub fn parser_should_return_token_test() {
  let data = "A --> |23| B"
  let token =
    parser.new_lexer(data)
    |> parser.next_token
    |> should.be_some
    |> should.equal(parser.Ident(text: "A"))
}
