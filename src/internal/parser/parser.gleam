import error
import gleam/option.{type Option, None}
import gleam/string
import gleam/bool
import simplifile

pub type Lexer {
  Lexer(data: String, data_length: Int, cursor: Int)
}

pub fn new_lexer(data: String) -> Lexer {
  Lexer(data, string.length(data), 0)
}

pub type Token {
  Ident(text: String)
  Arrow(text: String)
  Number(text: String, value: Int)
  Bar(text: String)
  EOF
}

fn has_tokens(lexer: Lexer) -> Bool {
  lexer.cursor < lexer.data_length
}

fn skip_whitespace(lexer: Lexer) -> Lexer {
  case string.pop_grapheme(lexer.data) {
    Ok(#(" ", rest)) | Ok(#("\t", rest)) -> {
      skip_whitespace(Lexer(..lexer, data: rest, cursor: lexer.cursor + 1))
    }
    _ -> lexer
  }
}

pub fn next_token(lexer: Lexer) -> Option(Token) {
  use <- bool.guard(when: has_tokens(lexer), return: None)
}

pub fn tokens_to_list(lexer: Lexer) -> List(Token) {
  todo
}

pub fn parse_file(uri: String) -> Result(List(String), error.Error) {
  case simplifile.read(uri) {
    Ok(text) -> {
      let tokens = new_lexer(text) |> tokens_to_list
      todo
    }
    Error(err) -> Error(error.io_error("Could not read updated file", err))
  }
}
