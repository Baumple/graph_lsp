import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/option.{type Option, Some}
import gleam/pair
import gleam/result
import gleam/string
import pprint
import rpc_types
import simplifile
import standard_io

const log_file = "/home/linusz/Desktop/text.txt"

fn log(x) {
  let assert Ok(_) =
    simplifile.append(to: log_file, contents: pprint.format(x) <> "\n")
  x
}

pub fn parse_content_length(line: String) -> Option(Int) {
  line
  |> string.trim
  |> string.split_once(": ")
  |> result.unwrap(or: #("", ""))
  |> pair.second
  |> int.parse
  |> option.from_result
}

fn read_request() -> String {
  let assert Some(content_length) =
    standard_io.get_line()
    |> parse_content_length
    |> log

  // remove "\r\n"
  standard_io.get_bytes(2)
  let request =
    standard_io.get_bytes(content_length)
    |> log
    |> rpc_types.from_json_request
    |> log
  ""
}

pub fn main() {
  io.println("1")
  let text =
    read_request()
    |> io.debug

  process.sleep_forever()
  Ok(Nil)
}
