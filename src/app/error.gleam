import gleam/list

pub type AppError {
  ProductValidation(
    name: List(String),
    quantity: List(String),
    urgent: List(String),
  )
}

pub fn messages_for(field: a, errors: List(#(a, b))) -> List(b) {
  errors
  |> list.filter_map(fn(e) {
    case e {
      #(f, msg) if f == field -> Ok(msg)
      _ -> Error(Nil)
    }
  })
}
