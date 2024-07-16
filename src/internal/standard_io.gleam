/// IO devices for erlang
pub type StandardIO {
  StandardIO
}

/// get `count` chars fom io_device with given `prompt` and return input
@external(erlang, "io", "get_chars")
pub fn get_chars(io_device: StandardIO, prompt: String, count: Int) -> String

/// `Prompt` the user for input and read entire line from stdin
@external(erlang, "io", "get_line")
pub fn prompt_input(prompt: String) -> String

/// Read `count` bytes from stdin
pub fn get_bytes(count: Int) -> String {
  get_chars(StandardIO, "", count)
}

/// Read an entire line from stdin (no prompt)
pub fn get_line() -> String {
  prompt_input("")
}
