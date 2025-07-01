import pog
import wisp

pub type Ctx {
  Ctx(static_dir: String, db: pog.Connection)
}

pub fn middleware(
  req: wisp.Request,
  ctx: Ctx,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_dir)

  handle_request(req)
}

pub fn get_static_dir_path() {
  let assert Ok(priv_directory) = wisp.priv_directory("shopping")
  priv_directory <> "/static"
}
