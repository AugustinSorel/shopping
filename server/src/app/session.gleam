import error
import gleam/dynamic/decode
import gleam/float
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import pog
import wisp

pub type Session {
  Session(
    id: String,
    user_id: Int,
    secret_hash: BitArray,
    last_verified_at: timestamp.Timestamp,
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
  )
}

pub type DecodedToken {
  DecodedToken(session_id: String, session_secret: String)
}

const separator = "."

const cookie_name = "session_token"

pub fn encode_token(session_id: String, secret: String) {
  [session_id, secret] |> string.join(with: separator)
}

pub fn set_cookie(res: wisp.Response, req: wisp.Request, token: String) {
  wisp.set_cookie(
    res,
    req,
    name: cookie_name,
    value: token,
    security: wisp.Signed,
    max_age: 24 |> duration.hours |> duration.to_seconds |> float.round,
  )
}

pub fn delete_cookie(res: wisp.Response, req: wisp.Request) {
  wisp.set_cookie(
    res,
    req,
    name: cookie_name,
    value: "",
    security: wisp.Signed,
    max_age: 0,
  )
}

pub fn get_cookie(req: wisp.Request) {
  wisp.get_cookie(req, cookie_name, wisp.Signed)
}

pub fn insert(
  id id: String,
  secret_hash secret_hash: BitArray,
  user_id user_id: Int,
  db db: pog.Connection,
) {
  let query = {
    "insert into sessions (id, secret_hash, user_id) VALUES ($1, $2, $3) returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(id))
    |> pog.parameter(pog.bytea(secret_hash))
    |> pog.parameter(pog.int(user_id))
    |> pog.returning(session_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [session, ..])) -> Ok(session)
    Ok(pog.Returned(_i, [])) -> Error(error.SessionNotFound)
    Error(_) -> Error(error.Internal(msg: "creating session failed"))
  }
}

fn session_row_decoder() {
  use id <- decode.field(0, decode.string)
  use user_id <- decode.field(1, decode.int)
  use secret_hash <- decode.field(2, decode.bit_array)
  use last_verified_at <- decode.field(3, pog.timestamp_decoder())
  use created_at <- decode.field(4, pog.timestamp_decoder())
  use updated_at <- decode.field(5, pog.timestamp_decoder())

  decode.success(Session(
    id:,
    user_id:,
    secret_hash:,
    last_verified_at:,
    created_at:,
    updated_at:,
  ))
}
