import gleam/bit_array
import gleam/bool
import gleam/dynamic/decode
import gleam/float
import gleam/order
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import pog
import server/auth
import server/error
import server/user
import server/web
import shared/context
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

pub type SessionWithUser {
  SessionWithUser(
    id: String,
    user_id: Int,
    secret_hash: BitArray,
    last_verified_at: timestamp.Timestamp,
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
    user: user.User,
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

fn get_by_id(id: String, db: pog.Connection) {
  let query = {
    "select * from sessions inner join users on users.id = sessions.user_id where sessions.id = $1"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(id))
    |> pog.returning(session_with_user_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [session, ..])) -> Ok(session)
    Ok(pog.Returned(_i, [])) -> Error(error.SessionNotFound)
    Error(_) -> Error(error.Internal(msg: "fetching session failed"))
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
    Error(_) -> Error(error.Internal(msg: "deleting session failed"))
  }
}

fn refresh_last_verified_at(id: String, db: pog.Connection) {
  let query = {
    "update sessions set last_verified_at = now() where id = $1 returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(id))
    |> pog.returning(session_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [session, ..])) -> Ok(session)
    Ok(pog.Returned(_i, [])) -> Error(error.SessionNotFound)
    Error(_) -> Error(error.Internal(msg: "refreshing session failed"))
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

fn session_with_user_decoder() {
  use id <- decode.field(0, decode.string)
  use user_id <- decode.field(1, decode.int)
  use secret_hash <- decode.field(2, decode.bit_array)
  use last_verified_at <- decode.field(3, pog.timestamp_decoder())
  use created_at <- decode.field(4, pog.timestamp_decoder())
  use updated_at <- decode.field(5, pog.timestamp_decoder())
  use email <- decode.field(7, decode.string)
  use password <- decode.field(8, decode.string)
  use user_created_at <- decode.field(9, pog.timestamp_decoder())
  use user_updated_at <- decode.field(10, pog.timestamp_decoder())

  decode.success(SessionWithUser(
    id:,
    user_id:,
    secret_hash:,
    last_verified_at:,
    created_at:,
    updated_at:,
    user: user.User(
      id: user_id,
      email:,
      password:,
      created_at: user_created_at,
      updated_at: user_updated_at,
    ),
  ))
}

fn decode_token(token: String) {
  let split =
    token
    |> string.split_once(on: separator)
    |> result.replace_error(error.SessionTokenValidation)

  use #(session_id, session_secret) <- result.try(split)

  Ok(DecodedToken(session_id:, session_secret:))
}

fn compare_max_age(to to: timestamp.Timestamp) {
  let now = timestamp.system_time()
  let age = timestamp.difference(now, to)

  let max_age = duration.hours(24)

  duration.compare(age, max_age)
}

pub fn validate(candidate_token: String, ctx: web.Ctx) {
  use decoded_token <- result.try(decode_token(candidate_token))

  let session = get_by_id(decoded_token.session_id, ctx.db)

  use session <- result.try(session)

  let session_expired = case compare_max_age(to: session.last_verified_at) {
    order.Gt -> {
      delete(decoded_token.session_id, ctx.db)
      |> result.unwrap_error(error.SessionExpired)
      |> Error
    }
    _ -> Ok(Nil)
  }

  use _ <- result.try(session_expired)

  let valid_secret = {
    decoded_token.session_secret
    |> bit_array.from_string
    |> auth.sha512_hash
    |> auth.sha512_compare(session.secret_hash)
  }

  use <- bool.guard(
    when: !valid_secret,
    return: Error(error.SessionSecretInvalid),
  )

  let refresh_session = case compare_max_age(to: session.last_verified_at) {
    order.Gt -> {
      refresh_last_verified_at(session.id, ctx.db)
      |> result.replace(Nil)
    }
    _ -> Ok(Nil)
  }

  use _ <- result.try(refresh_session)

  Ok(context.Session(
    id: session.id,
    user: context.User(id: session.user.id, email: session.user.email),
  ))
}
