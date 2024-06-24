import pprint

pub type Error {
  DecodeError(message: String)
}

pub fn to_decode_error(error) {
  DecodeError(message: "Error while decoding: " <> pprint.format(error))
}
