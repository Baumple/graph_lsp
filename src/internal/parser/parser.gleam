import gleam/option
import gleeunit/should
import internal/rpc/rpc

pub fn parse_content_length_test() {
  let parse = rpc.parse_content_length
  parse("Content-Length: 100\n")
  |> should.equal(option.Some(100))

  parse("Content-Length")
  |> should.be_none

  parse("")
  |> should.be_none
}
