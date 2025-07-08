import app/web
import gleam/http
import gleam/option
import gleam/result
import product/product_handler
import session/session_handler
import session/session_service
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use req <- web.middleware(req)

  let session =
    req
    |> session_service.get_cookie()
    |> result.unwrap("")
    |> session_service.validate(ctx)
    |> option.from_result

  let ctx = web.Ctx(..ctx, session:)

  case wisp.path_segments(req) {
    [] -> wisp.redirect(to: "/products")

    ["products"] -> products(req, ctx)
    ["products", "create"] -> products_create(req)
    ["products", product_id, "bought"] -> product_bought(req, ctx, product_id)

    ["auth", "sign-up"] -> sign_up(req, ctx)
    ["auth", "sign-out"] -> sign_out(req, ctx)

    _ -> wisp.not_found()
  }
}

fn sign_up(req: wisp.Request, ctx: web.Ctx) {
  case req.method {
    http.Get -> session_handler.sign_up_page(req, ctx)
    http.Post -> session_handler.sign_up(req, ctx)

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn sign_out(req: wisp.Request, ctx: web.Ctx) {
  use <- wisp.require_method(req, http.Post)

  session_handler.sign_out(req, ctx)
}

fn products_create(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> product_handler.create_page(req)

    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn products(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  case req.method {
    http.Get -> product_handler.by_purchased_status_page(req, ctx)
    http.Post -> product_handler.create(req, ctx)

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn product_bought(
  req: wisp.Request,
  ctx: web.Ctx,
  product_id: String,
) -> wisp.Response {
  case req.method {
    http.Post -> product_handler.create_bought(ctx, product_id)
    http.Delete -> product_handler.delete_bought(ctx, product_id)

    _ -> wisp.method_not_allowed([http.Delete, http.Post])
  }
}
