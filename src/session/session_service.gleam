import app/error
import app/web
import auth/auth_service
import gleam/bit_array
import gleam/bool
import gleam/float
import gleam/order
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import session/session_model
import session/session_repo
import wisp

const separator = "."

const cookie_name = "session_token"

pub fn encode_token(session_id: String, secret: String) {
  [session_id, secret] |> string.join(with: separator)
}

pub fn decode_token(token: String) {
  let split = token |> string.split_once(on: separator)

  case split {
    Ok(#(session_id, session_secret)) -> {
      Ok(session_model.DecodedToken(session_id:, session_secret:))
    }
    Error(_) -> Error(error.SessionTokenValidation)
  }
}

pub fn compare_max_age(to to: timestamp.Timestamp) {
  let now = timestamp.system_time()
  let age = timestamp.difference(now, to)

  let max_age = duration.hours(24)

  duration.compare(age, max_age)
}

pub fn set_cookie(res: wisp.Response, req: wisp.Request, token: String) {
  wisp.set_cookie(
    res,
    req,
    name: cookie_name,
    value: token,
    security: wisp.PlainText,
    max_age: 24 |> duration.hours |> duration.to_seconds |> float.round,
  )
}

pub fn delete_cookie(res: wisp.Response, req: wisp.Request) {
  wisp.set_cookie(
    res,
    req,
    name: cookie_name,
    value: "",
    security: wisp.PlainText,
    max_age: 0,
  )
}

pub fn get_cookie(req: wisp.Request) {
  wisp.get_cookie(req, cookie_name, wisp.PlainText)
}

pub fn validate(candidate_token: String, ctx: web.Ctx) {
  use decoded_token <- result.try(decode_token(candidate_token))

  let session = session_repo.get_by_id(decoded_token.session_id, ctx.db)

  use session <- result.try(session)

  let session_expired = case compare_max_age(to: session.last_verified_at) {
    order.Gt -> {
      session_repo.delete(decoded_token.session_id, ctx.db)
      |> result.unwrap_error(error.SessionExpired)
      |> Error
    }
    _ -> Ok(Nil)
  }

  use _ <- result.try(session_expired)

  let valid_secret = {
    decoded_token.session_secret
    |> bit_array.from_string
    |> auth_service.sha512_hash
    |> auth_service.sha512_compare(session.secret_hash)
  }

  use <- bool.guard(
    when: !valid_secret,
    return: Error(error.SessionSecretInvalid),
  )

  let refresh_session = case compare_max_age(to: session.last_verified_at) {
    order.Gt -> {
      session_repo.refresh_last_verified_at(session.id, ctx.db)
      |> result.replace(Nil)
    }
    _ -> Ok(Nil)
  }

  use _ <- result.try(refresh_session)

  Ok(session)
}
