import app/error
import gleam/dynamic/decode
import pog
import session/session_model

pub fn create(
  id id: String,
  secret_hash secret_hash: BitArray,
  db db: pog.Connection,
) {
  let query = {
    "insert into sessions (id, secret_hash) VALUES ($1, $2) returning *"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.string)
    use secret_hash <- decode.field(1, decode.bit_array)
    use last_verified_at <- decode.field(2, pog.timestamp_decoder())
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())

    decode.success(session_model.Session(
      id:,
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
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [session, ..])) -> Ok(session)
    _ -> Error(error.Internal("creating session failed"))
  }
}

pub fn get_by_id(id: String, db: pog.Connection) {
  let query = {
    "select * from sessions where id = $1"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.string)
    use secret_hash <- decode.field(1, decode.bit_array)
    use last_verified_at <- decode.field(2, pog.timestamp_decoder())
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())

    decode.success(session_model.Session(
      id:,
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
    use secret_hash <- decode.field(1, decode.bit_array)
    use last_verified_at <- decode.field(2, pog.timestamp_decoder())
    use created_at <- decode.field(3, pog.timestamp_decoder())
    use updated_at <- decode.field(4, pog.timestamp_decoder())

    decode.success(session_model.Session(
      id:,
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
