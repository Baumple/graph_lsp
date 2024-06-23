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
