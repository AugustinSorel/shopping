import client
import client/network
import formal/form
import gleam/bit_array
import gleam/bool
import gleam/http
import gleam/int
import gleam/option
import gleam/result
import gleam/string_tree
import lustre/attribute
import lustre/element
import lustre/element/html
import pog
import server/auth
import server/error
import server/product
import server/session
import server/user
import server/web
import shared/context
import shared/product as shared_product
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

    [] -> home(req, ctx)

    ["products"] -> products(req, ctx)

    ["users", "account"] -> user_account(req, ctx)

    ["products", "create"] -> products_create(req, ctx)

    ["products", product_id, "bought"] -> product_bought(req, product_id, ctx)

    _ -> wisp.not_found()
  }
}

fn home(req, ctx) {
  use <- wisp.require_method(req, http.Get)
  use <- wisp.require_method(req, http.Get)

  use session <- web.auth_guard(ctx)

  let products_by_status = product.get_by_purchase_status(ctx.db)

  use products_by_status <- web.require_ok(products_by_status)

  client.view(client.Products(
    state: network.Success(products_by_status),
    session:,
  ))
  |> web.layout(
    session: option.Some(session),
    payload: option.Some(html.script(
      [
        attribute.type_("application/json"),
        attribute.id(shared_product.products_by_status_hydration_key),
      ],
      shared_product.encode_products_by_status(products_by_status),
    )),
  )
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}

fn sign_up(req: wisp.Request, ctx: web.Ctx) {
  case req.method {
    http.Get -> {
      use <- web.guest_only(ctx)

      client.view(client.SignUp(form: form.new(), state: network.Idle))
      |> web.layout(session: option.None, payload: option.None)
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
        user: context.User(id: user.id, email: user.email),
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

      client.view(client.SignIn(form: form.new(), state: network.Idle))
      |> web.layout(session: option.None, payload: option.None)
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
        user: context.User(id: user.id, email: user.email),
      ))
      |> string_tree.from_string()
      |> wisp.json_response(wisp.created().status)
      |> session.set_cookie(req, token)
    }

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn products(req: wisp.Request, ctx: web.Ctx) {
  case req.method {
    http.Get -> {
      use _session <- web.auth_guard(ctx)

      let products_by_status = product.get_by_purchase_status(ctx.db)

      use products_by_status <- web.require_ok(products_by_status)

      products_by_status
      |> shared_product.encode_products_by_status()
      |> string_tree.from_string()
      |> wisp.json_response(wisp.ok().status)
    }
    http.Post -> {
      use session <- web.auth_guard(ctx)

      use json <- wisp.require_json(req)

      let product = product.decode_create_product(json)

      use product <- web.require_ok(product)

      let product = product.insert(product, session.user.id, ctx.db)

      use _product <- web.require_ok(product)

      wisp.created()
    }
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
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

  client.view(client.Account(sign_out_state: network.Idle, session:))
  |> web.layout(session: option.Some(session), payload: option.None)
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}

fn products_create(req: wisp.Request, ctx: web.Ctx) {
  use <- wisp.require_method(req, http.Get)

  use session <- web.auth_guard(ctx)

  client.view(client.CreateProduct(
    form: form.initial_values([#("quantity", "1")]),
    state: network.Idle,
    session:,
  ))
  |> web.layout(session: option.Some(session), payload: option.None)
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}

fn product_bought(req: wisp.Request, product_id: String, ctx: web.Ctx) {
  use <- wisp.require_method(req, http.Patch)

  use _session <- web.auth_guard(ctx)

  use json <- wisp.require_json(req)

  let input = product.decode_patch_product(json)

  let product_id = {
    int.parse(product_id)
    |> result.replace_error(
      error.ProductValidation(errors: [
        error.Validation(field: "product_id", msg: "product id is invalid"),
      ]),
    )
  }

  use product_id <- web.require_ok(product_id)

  use input <- web.require_ok(input)

  let product = product.patch_bought(input.bought, product_id, ctx.db)

  use _product <- web.require_ok(product)

  wisp.ok()
}
