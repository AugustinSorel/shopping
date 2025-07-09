import app/error
import gleam/dynamic/decode
import pog
import session/session_model
import user/user_model

pub fn create(
  id id: String,
  secret_hash secret_hash: BitArray,
  user_id user_id: Int,
  db db: pog.Connection,
) {
  let query = {
    "insert into sessions (id, secret_hash, user_id) VALUES ($1, $2, $3) returning *"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.string)
    use user_id <- decode.field(1, decode.int)
    use secret_hash <- decode.field(2, decode.bit_array)
    use last_verified_at <- decode.field(3, pog.timestamp_decoder())
    use created_at <- decode.field(4, pog.timestamp_decoder())
    use updated_at <- decode.field(5, pog.timestamp_decoder())

    decode.success(session_model.Session(
      id:,
      user_id:,
      secret_hash:,
      last_verified_at:,
      created_at:,
      updated_at:,
    ))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(id))
    |> pog.parameter(pog.bytea(secret_hash))
    |> pog.parameter(pog.int(user_id))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [session, ..])) -> Ok(session)
    _ -> Error(error.Internal("creating session failed"))
  }
}

pub fn get_by_id(id: String, db: pog.Connection) {
  let query = {
    "select sessions.id, sessions.last_verified_at, sessions.secret_hash, users.id, users.email from sessions inner join users on users.id = sessions.user_id where sessions.id = $1"
  }

  let row_decoder = {
    use session_id <- decode.field(0, decode.string)
    use last_verified_at <- decode.field(1, pog.timestamp_decoder())
    use secret_hash <- decode.field(2, decode.bit_array)
    use user_id <- decode.field(3, decode.int)
    use email <- decode.field(4, decode.string)

    decode.success(session_model.SessionWithUser(
      id: session_id,
      last_verified_at:,
      secret_hash:,
      user: user_model.CtxUser(id: user_id, email:),
    ))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(id))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [session, ..])) -> Ok(session)
    _ -> Error(error.Internal("fetching session failed"))
  }
}

pub fn delete(id: String, db: pog.Connection) {
  let query = {
    "delete from sessions where id = $1"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(id))
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, _rows)) -> Ok(Nil)
    _ -> Error(error.Internal("deleting session failed"))
  }
}

pub fn refresh_last_verified_at(id: String, db: pog.Connection) {
  let query = {
    "update sessions set last_verified_at = now() where id = $1 returning *"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.string)
    use user_id <- decode.field(1, decode.int)
    use secret_hash <- decode.field(2, decode.bit_array)
    use last_verified_at <- decode.field(3, pog.timestamp_decoder())
    use created_at <- decode.field(4, pog.timestamp_decoder())
    use updated_at <- decode.field(5, pog.timestamp_decoder())

    decode.success(session_model.Session(
      id:,
      user_id:,
      secret_hash:,
      last_verified_at:,
      created_at:,
      updated_at:,
    ))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(id))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [session, ..])) -> Ok(session)
    _ -> Error(error.Internal("refreshing session last verified at failed"))
  }
}
