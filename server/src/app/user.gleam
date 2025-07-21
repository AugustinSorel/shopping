import error
import gleam/dynamic/decode
import gleam/result
import pog
import shared/user

pub fn insert(email: String, password: String, db: pog.Connection) {
  let query = {
    "insert into users (email, password) VALUES ($1, $2) returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(email))
    |> pog.parameter(pog.text(password))
    |> pog.returning(user_row_decoder())
    |> pog.execute(db)

  let response = case response {
    Ok(pog.Returned(_i, [user, ..])) -> Ok(user)
    Ok(pog.Returned(_i, [])) -> Error(error.UserNotFound)
    Error(pog.ConstraintViolated(_, _, _)) -> Error(error.UserConflict)
    Error(_) -> Error(error.Internal("creating user failed"))
  }

  use user <- result.try(response)

  Ok(user)
}

fn user_row_decoder() {
  use id <- decode.field(0, decode.int)
  use email <- decode.field(1, decode.string)
  use password <- decode.field(2, decode.string)
  use created_at <- decode.field(3, pog.timestamp_decoder())
  use updated_at <- decode.field(4, pog.timestamp_decoder())

  decode.success(user.User(id:, email:, password:, created_at:, updated_at:))
}
