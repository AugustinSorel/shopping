import app/env
import gleam/option
import pog
import session/session_model
import wisp

pub type Ctx {
  Ctx(
    db: pog.Connection,
    env: env.Env,
    session: option.Option(session_model.Session),
  )
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  let static_dir = get_static_dir()

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: static_dir)

  handle_request(req)
}

pub fn get_static_dir() {
  let assert Ok(priv_directory) = wisp.priv_directory("shopping")
  priv_directory <> "/static"
}
