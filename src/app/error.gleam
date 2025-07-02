import gleam/list
import gleam/option

pub type AppError {
  ProductValidation(
    title: option.Option(List(String)),
    quantity: option.Option(List(String)),
    location: option.Option(List(String)),
    urgent: option.Option(List(String)),
  )
  Internal
}

pub fn messages_for(field: a, errors: List(#(a, b))) -> option.Option(List(b)) {
  let errors = {
    list.filter_map(errors, fn(e) {
      case e {
        #(f, msg) if f == field -> Ok(msg)
        _ -> Error(Nil)
      }
    })
  }

  case errors {
    [] -> option.None
    _ -> option.Some(errors)
  }
}
