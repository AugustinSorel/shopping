import gleam/list
import gleam/result
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
