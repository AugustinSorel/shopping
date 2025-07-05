import app/web
import gleam/http
import product/product_handler
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> wisp.redirect(to: "/products")

    ["products"] -> products(req, ctx)

    ["products", "create"] -> products_create(req)

    ["products", product_id, "bought"] -> product_bought(req, ctx, product_id)

    _ -> wisp.not_found()
  }
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
