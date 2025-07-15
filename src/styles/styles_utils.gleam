import gleam/int
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute
import lustre/vdom/vattr

pub fn extract_class(attrs: List(attribute.Attribute(msg))) {
  attrs
  |> find_class_attr
  |> extract_class_from_res
  |> result.unwrap("")
}

fn find_class_attr(attr: List(attribute.Attribute(msg))) {
  list.find(attr, fn(attr) {
    case attr.name {
      "class" -> True
      _ -> False
    }
  })
}

fn extract_class_from_res(res: Result(attribute.Attribute(msg), Nil)) {
  result.map(res, fn(attr) {
    case attr {
      vattr.Attribute(value:, ..) -> value
      _ -> ""
    }
  })
}

fn char_to_int(char: String) -> Int {
  case string.to_utf_codepoints(char) {
    [codepoint] -> string.utf_codepoint_to_int(codepoint)
    _ -> 0
  }
}

pub fn hue_from_string(input: String) -> String {
  let input_as_int = {
    string.to_graphemes(input)
    |> list.fold(0, fn(prev, curr) { prev + char_to_int(curr) })
  }

  let hue = int.bitwise_shift_left(input_as_int, 5)

  int.to_string(hue)
}
