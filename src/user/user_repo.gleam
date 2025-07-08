import app/error
import gleam/dynamic/decode
import pog
import user/user_model

pub fn create(email: String, password: String, db: pog.Connection) {
  let query = {
    "insert into users (email, password) VALUES ($1, $2) returning *"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())

    decode.success(user_model.User(
      id:,
      email:,
      password:,
      created_at:,
      updated_at:,
    ))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(email))
    |> pog.parameter(pog.text(password))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [user, ..])) -> Ok(user)
    Error(pog.ConstraintViolated(_, _, _)) -> Error(error.UserConflict)
    _ -> Error(error.Internal("creating user failed"))
  }
}

pub fn get_by_email(email: String, db: pog.Connection) {
  let query = {
    "select * from users where email = $1"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use email <- decode.field(1, decode.string)
    use password <- decode.field(2, decode.string)
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())

    decode.success(user_model.User(
      id:,
      email:,
      password:,
      created_at:,
      updated_at:,
    ))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(email))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [user, ..])) -> Ok(user)
    Ok(pog.Returned(_i, [])) -> Error(error.UserNotFound)
    _ -> Error(error.Internal(msg: "fetching user by email failed"))
  }
}
