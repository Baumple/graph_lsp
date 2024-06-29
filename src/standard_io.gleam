import pprint
import simplifile
import gleam/io

pub type StandardIO {
  StandardIO
}

@external(erlang, "io", "get_chars")
pub fn get_chars(io_device: StandardIO, prompt: String, count: Int) -> String

@external(erlang, "io", "get_line")
pub fn prompt_input(prompt: String) -> String

pub fn get_bytes(count: Int) -> String {
  get_chars(StandardIO, "", count)
}

pub fn get_line() -> String {
  prompt_input("")
}

const log_file = "/home/linusz/Desktop/text.txt"

pub fn init_logger() {
  let _ = simplifile.delete(log_file)
  Nil
}

pub fn log_error(x) {
  let f = pprint.format(x) <> "\n"
  io.println_error(f)
  x
}

pub fn log_error_panic(x) {
  let f = pprint.format(x) <> "\n"
  io.println_error(f <> "\n")
  let assert Ok(_) = simplifile.append(log_file, f)
  panic as f
}
