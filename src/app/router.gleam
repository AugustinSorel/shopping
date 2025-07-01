import gleam/http
import product/product_handler
import wisp

pub fn handle_request(req: wisp.Request) -> wisp.Response {
  use req <- middleware(req)

  case wisp.path_segments(req) {
    [] -> wisp.redirect(to: "/products")

    ["products"] -> products(req)

    ["products", "create"] -> products_create(req)

    _ -> wisp.not_found()
  }
}

fn products_create(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> product_handler.create_form()

    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn products(req: wisp.Request) -> wisp.Response {
  case req.method {
    http.Get -> product_handler.by_purchased_status()
    http.Post -> product_handler.create(req)

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)

  handle_request(req)
}
