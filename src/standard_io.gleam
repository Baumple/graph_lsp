import pprint
import simplifile

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

const error_file = "/home/linusz/Desktop/error.txt"

pub fn init_logger() {
  let _ = simplifile.delete(log_file)
  Nil
}

pub fn log(x) {
  let assert Ok(_) =
    simplifile.append(to: log_file, contents: pprint.format(x) <> "\n")
  x
}

pub fn log_error(x) {
  let assert Ok(_) =
    simplifile.append(to: error_file, contents: pprint.format(x) <> "\n")
  panic
}
