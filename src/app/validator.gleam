import gleam/option
import gleam/string
import valid

pub fn string_is_bool(error error: err) -> valid.Validator(String, Bool, err) {
  fn(input: String) {
    case input {
      "on" -> #(True, [])
      "True" -> #(True, [])
      "off" -> #(False, [])
      "False" -> #(False, [])
      _ -> #(False, [error])
    }
  }
}

pub fn trim() -> valid.Validator(String, String, err) {
  fn(input: String) { #(string.trim(input), []) }
}

pub fn empty_str_as_none() {
  fn(input: option.Option(String)) {
    case input {
      option.Some("") -> #(option.None, [])
      _ -> #(input, [])
    }
  }
}
