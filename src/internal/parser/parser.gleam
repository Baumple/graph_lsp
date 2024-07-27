import error
import gleam/bool
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

pub type Lexer {
  Lexer(data: String, data_length: Int, cursor: Int)
}

pub fn new_lexer(data: String) -> Lexer {
  Lexer(data, string.length(data), 0)
}

pub opaque type Token {
  Ident(text: String)
  Arrow(text: String)
  Number(text: String, value: Int)
  Bar(text: String)
  Illegal(text: String)
}

/// Advances the lexer while a given predicate returns true
fn advance(
  lexer: Lexer,
  while condition: fn(String) -> Bool,
) -> #(String, Lexer) {
  advance_acc(lexer, while: condition, with: "")
}

fn advance_acc(
  lexer: Lexer,
  while condition: fn(String) -> Bool,
  with acc: String,
) -> #(String, Lexer) {
  result.try(string.pop_grapheme(lexer.data), fn(pooped) {
    // Destructure the popped character from the rest of the data
    let #(c, rest) = pooped
    // If the condition is met, advance the lexer, otherwise return current
    // state
    bool.lazy_guard(
      when: condition(c),
      return: fn() {
        advance_acc(
          Lexer(..lexer, data: rest, cursor: lexer.cursor + 1),
          while: condition,
          with: acc <> c,
        )
      },
      otherwise: fn() { #(acc, lexer) },
    )
    |> Ok
  })
  |> result.unwrap(or: #(acc, lexer))
}

fn is_empty(lexer: Lexer) -> Bool {
  lexer.cursor < lexer.data_length
}

/// skip_whitespace increments the cursor by one as long as it encounters
/// a space character. 
///
/// It returns a tuple [#(Option(String), Lexer)] of the current character (or none if
/// data is empty) and the updated lexer
pub fn skip_whitespace(lexer: Lexer) -> Lexer {
  let #(_white_space, lexer) = advance(lexer, while: is_whitespace)
  lexer
}

/// Pop a grapheme from the lexer's data (error on empty)
/// checks whether a given string consists of digits only
pub fn is_num(s: String) -> Bool {
  s
  |> string.to_graphemes
  |> list.map(fn(c) {
    case c {
      "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
      _ -> False
    }
  })
  |> list.all(function.identity)
}

pub fn is_special(c: String) -> Bool {
  c
  |> string.first
  |> result.map(fn(c) {
    bool.negate(is_alpha(c) || is_num(c) || is_whitespace(c))
  })
  |> result.unwrap(or: False)
}

pub fn is_whitespace(c: String) -> Bool {
  c
  |> string.to_utf_codepoints
  |> list.map(string.utf_codepoint_to_int)
  |> list.all(fn(x) { { x >= 9 && x <= 13 } || x == 32 })
}

pub fn is_alpha(c: String) -> Bool {
  c
  |> string.to_utf_codepoints
  |> list.all(fn(codepoint) {
    case string.utf_codepoint_to_int(codepoint) {
      x if x >= 65 && x <= 90 -> True
      x if x >= 97 && x <= 122 -> True
      _ -> False
    }
  })
}

fn parse_num(lexer: Lexer) -> #(Token, Lexer) {
  let #(text, lexer) = advance(lexer, while: is_num)

  let parsed = int.parse(text)
  #(Number(text: text, value: result.unwrap(parsed, or: 0)), lexer)
}

fn parse_special(lexer: Lexer) -> #(Token, Lexer) {
  let #(text, lexer) = advance(lexer, while: is_special)
  #(
    case text {
      "-->" -> Arrow(text)
      "|" -> Bar(text)
      _ -> Illegal(text)
    },
    lexer,
  )
}

fn parse_alpha(lexer: Lexer) -> #(Token, Lexer) {
  let #(text, lexer) = advance(lexer, while: is_alpha)
  #(Ident(text), lexer)
}

pub fn next_token(lexer: Lexer) -> #(Option(Token), Lexer) {
  use <- bool.guard(when: !is_empty(lexer), return: #(None, lexer))
  let lexer = skip_whitespace(lexer)
  let c = string.first(lexer.data)

  case c {
    Ok(c) ->
      {
        use <- bool.lazy_guard(when: is_num(c), return: fn() {
          parse_num(lexer)
        })
        bool.lazy_guard(
          when: is_special(c),
          return: fn() { parse_special(lexer) },
          otherwise: fn() { parse_alpha(lexer) },
        )
      }
      |> fn(res: #(Token, Lexer)) { #(Some(res.0), res.1) }
    _ -> #(None, lexer)
  }
}

pub fn tokens_to_list(lexer: Lexer) -> List(Token) {
  case next_token(lexer) {
    #(Some(token), lexer) -> [token, ..tokens_to_list(lexer)]
    #(None, _) -> []
  }
}

pub fn parse_file(uri: String) -> Result(List(Token), error.Error) {
  case simplifile.read(uri) {
    Ok(text) -> {
      new_lexer(text) |> tokens_to_list |> Ok
    }
    Error(err) -> Error(error.io_error("Could not read updated file", err))
  }
}

pub fn filter_ident(token: Token) -> Bool {
  case token {
    Ident(..) -> True
    _ -> False
  }
}

pub fn get_token_text(token: Token) -> String {
  token.text
}
