import error
import gleam/dynamic/decode
import gleam/result
import gleam/time/timestamp
import pog

pub type User {
  User(
    id: Int,
    email: String,
    password: String,
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
  )
}

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

pub fn get_by_email(email: String, db: pog.Connection) {
  let query = {
    "select * from users where email = $1"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(email))
    |> pog.returning(user_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [user, ..])) -> Ok(user)
    Ok(pog.Returned(_i, [])) -> Error(error.UserNotFound)
    Error(_) -> Error(error.Internal(msg: "fetching user by email failed"))
  }
}

fn user_row_decoder() {
  use id <- decode.field(0, decode.int)
  use email <- decode.field(1, decode.string)
  use password <- decode.field(2, decode.string)
  use created_at <- decode.field(3, pog.timestamp_decoder())
  use updated_at <- decode.field(4, pog.timestamp_decoder())

  decode.success(User(id:, email:, password:, created_at:, updated_at:))
}
