import client
import client/auth as client_auth
import client/network
import client/product
import client/user as client_user
import formal/form
import gleam/bit_array
import gleam/bool
import gleam/http
import gleam/option
import gleam/result
import gleam/string_tree
import lustre/element
import pog
import server/auth
import server/error
import server/session
import server/user
import server/web
import shared/context
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use req <- web.middleware(req)

  let session =
    req
    |> session.get_cookie()
    |> result.unwrap("")
    |> session.validate(ctx)
    |> option.from_result

  let ctx = web.Ctx(..ctx, session:)
  case wisp.path_segments(req) {
    ["sign-up"] -> sign_up(req, ctx)
    ["sign-in"] -> sign_in(req, ctx)
    ["sign-out"] -> sign_out(req, ctx)

    [] | ["products"] -> products(req, ctx)

    ["users", "account"] -> user_account(req, ctx)

    _ -> wisp.not_found()
  }
}

fn sign_up(req: wisp.Request, ctx: web.Ctx) {
  case req.method {
    http.Get -> {
      use <- web.guest_only(ctx)

      client_auth.sign_up_view(
        form: form.new(),
        state: network.Idle,
        on_submit: client.UserSubmittedSignUpForm,
      )
      |> web.layout(session: option.None)
      |> element.to_document_string_tree
      |> wisp.html_response(200)
    }

    http.Post -> {
      use <- web.guest_only(ctx)

      use json <- wisp.require_json(req)

      let sign_up = auth.decode_sign_up(json)

      use sign_up <- web.require_ok(sign_up)

      let hashed_password = {
        sign_up.password |> bit_array.from_string |> auth.hash_secret
      }

      let tx =
        pog.transaction(ctx.db, fn(db) {
          let user = user.insert(sign_up.email, hashed_password, db)

          use user <- result.try(user)

          let session_id = wisp.random_string(64)
          let secret = wisp.random_string(64)
          let secret_hash = {
            secret |> bit_array.from_string |> auth.sha512_hash
          }

          let token = session.encode_token(session_id, secret)

          let session = session.insert(session_id, secret_hash, user.id, db)

          use session <- result.try(session)

          Ok(#(token, session, user))
        })
        |> result.map_error(fn(e) {
          case e {
            pog.TransactionQueryError(_) -> {
              error.Internal(msg: "somehting went wrong")
            }
            pog.TransactionRolledBack(e) -> e
          }
        })

      use #(token, session, user) <- web.require_ok(tx)

      context.encode_session(context.Session(
        id: session.id,
        user: context.User(email: user.email),
      ))
      |> string_tree.from_string()
      |> wisp.json_response(wisp.created().status)
      |> session.set_cookie(req, token)
    }
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn sign_in(req: wisp.Request, ctx: web.Ctx) {
  case req.method {
    http.Get -> {
      use <- web.guest_only(ctx)

      client_auth.sign_in_view(
        form: form.new(),
        state: network.Idle,
        on_submit: client.UserSubmittedSignInForm,
      )
      |> web.layout(session: option.None)
      |> element.to_document_string_tree
      |> wisp.html_response(200)
    }

    http.Post -> {
      use <- web.guest_only(ctx)

      use json <- wisp.require_json(req)

      let sign_in = auth.decode_sign_in(json)

      use sign_in <- web.require_ok(sign_in)

      let user = {
        user.get_by_email(sign_in.email, ctx.db)
        |> result.replace_error(error.InvalidCredentials)
      }

      use user <- web.require_ok(user)

      let password_valid = {
        sign_in.password
        |> bit_array.from_string
        |> auth.hash_verify(user.password)
      }

      let password_valid = {
        bool.guard(
          when: !password_valid,
          return: Error(error.InvalidCredentials),
          otherwise: fn() { Ok(Nil) },
        )
      }

      use _ <- web.require_ok(password_valid)

      let session_id = wisp.random_string(64)
      let secret = wisp.random_string(64)
      let secret_hash = {
        secret |> bit_array.from_string |> auth.sha512_hash
      }

      let token = session.encode_token(session_id, secret)

      let session = session.insert(session_id, secret_hash, user.id, ctx.db)

      use session <- web.require_ok(session)

      context.encode_session(context.Session(
        id: session.id,
        user: context.User(email: user.email),
      ))
      |> string_tree.from_string()
      |> wisp.json_response(wisp.created().status)
      |> session.set_cookie(req, token)
    }

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn products(req: wisp.Request, ctx: web.Ctx) {
  use <- wisp.require_method(req, http.Get)

  use session <- web.auth_guard(ctx)

  product.page(client.UserClickedSignOut)
  |> web.layout(session: option.Some(session))
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}

fn sign_out(req: wisp.Request, ctx: web.Ctx) {
  use <- wisp.require_method(req, http.Post)

  use session <- web.auth_guard(ctx)

  let res = session.delete(session.id, ctx.db)

  use _ <- web.require_ok(res)

  wisp.ok()
  |> session.delete_cookie(req)
}

fn user_account(req: wisp.Request, ctx: web.Ctx) {
  use <- wisp.require_method(req, http.Get)

  use session <- web.auth_guard(ctx)

  [client_user.preference(on_theme_change: client.UserChangedTheme)]
  |> client_user.account_page(session.user)
  |> web.layout(session: option.Some(session))
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}
