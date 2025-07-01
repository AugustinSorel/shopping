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
