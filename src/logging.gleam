import gleam/io
import pprint
import simplifile

const log_file = "/home/linusz/Desktop/text.txt"

const config = pprint.Config(
  pprint.Unstyled,
  pprint.BitArraysAsString,
  pprint.Labels,
)

pub fn init_logger() {
  let _ = simplifile.delete(log_file)
  Nil
}

pub fn log_error(x) {
  let f = pprint.with_config(x, config) <> "\n"
  io.println_error(f)
  x
}

pub fn log_error_panic(x) {
  let f = pprint.with_config(x, config) <> "\n"
  io.println_error(f <> "\n")
  let assert Ok(_) = simplifile.append(log_file, f)
  panic as f
}

pub fn log_to_file(x) {
  let f = pprint.with_config(x, config) <> "\n"
  let assert Ok(_) = simplifile.append(log_file, f)
  x
}
