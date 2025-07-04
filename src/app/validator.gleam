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

pub fn trim(input: String) {
  #(string.trim(input), [])
}

pub fn empty_str_as_none() {
  fn(input: option.Option(String)) {
    case input {
      option.Some("") -> #(option.None, [])
      _ -> #(input, [])
    }
  }
}

pub fn string_required(
  validator validator: valid.Validator(String, String, err),
  error error,
) {
  fn(maybe_input: option.Option(String)) {
    case maybe_input {
      option.None -> #("", [error])
      option.Some(input) -> {
        let #(output, errors) = validator(input)
        #(output, errors)
      }
    }
  }
}

pub fn pipe_str_to_int(
  first_validator first_validator: valid.Validator(String, String, err),
  second_validator second_validator: valid.Validator(String, Int, err),
) {
  fn(input) {
    case first_validator(input) {
      #(output, []) -> second_validator(output)
      #(_output, errors) -> #(0, errors)
    }
  }
}

pub fn pipe_str_to_bool(
  first_validator first_validator: valid.Validator(String, String, err),
  second_validator second_validator: valid.Validator(String, Bool, err),
) {
  fn(input) {
    case first_validator(input) {
      #(output, []) -> second_validator(output)
      #(_output, errors) -> #(False, errors)
    }
  }
}

pub fn default(
  validator validator: valid.Validator(input, output, err),
  default default,
) {
  fn(maybe_input: option.Option(input)) {
    case maybe_input {
      option.None -> #(default, [])
      option.Some(input) -> {
        let #(output, errors) = validator(input)
        #(output, errors)
      }
    }
  }
}
