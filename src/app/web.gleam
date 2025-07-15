import app/env
import gleam/option
import gleam/time/timestamp
import pog
import wisp

pub type CtxUser {
  CtxUser(id: Int, email: String)
}

pub type CtxSession {
  CtxSession(
    id: String,
    last_verified_at: timestamp.Timestamp,
    secret_hash: BitArray,
    user: CtxUser,
  )
}

pub type Ctx {
  Ctx(db: pog.Connection, env: env.Env, session: option.Option(CtxSession))
}

pub fn auth_guard(
  ctx: Ctx,
  cb: fn(CtxSession) -> wisp.Response,
) -> wisp.Response {
  case ctx.session {
    option.Some(session) -> cb(session)
    option.None -> wisp.redirect(to: "/sign-up")
  }
}

pub fn guest_only(ctx: Ctx, cb: fn() -> wisp.Response) -> wisp.Response {
  case ctx.session {
    option.Some(_) -> wisp.redirect(to: "/")
    option.None -> cb()
  }
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
