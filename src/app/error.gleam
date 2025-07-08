import gleam/list
import gleam/option

pub type AppError {
  ProductValidation(
    id: option.Option(List(String)),
    title: option.Option(List(String)),
    quantity: option.Option(List(String)),
    location: option.Option(List(String)),
    urgent: option.Option(List(String)),
  )
  SignUpValidation(
    email: option.Option(List(String)),
    password: option.Option(List(String)),
    confirm_password: option.Option(List(String)),
  )
  Internal(msg: String)
  SessionExpired
  SessionTokenValidation
  SessionSecretInvalid
  Unauthorized
  UserConflict
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
