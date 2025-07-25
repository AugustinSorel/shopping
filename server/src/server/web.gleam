import client/theme
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html
import pog
import server/env
import server/error
import shared/context
import wisp

pub type Ctx {
  Ctx(db: pog.Connection, env: env.Env, session: option.Option(context.Session))
}

pub fn auth_guard(
  ctx: Ctx,
  cb: fn(context.Session) -> wisp.Response,
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

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: get_static_dir())

  handle_request(req)
}

pub fn require_ok(
  c: Result(a, error.Error),
  cb: fn(a) -> wisp.Response,
) -> wisp.Response {
  case c {
    Error(e) -> error.build_response(e)
    Ok(v) -> cb(v)
  }
}

pub fn get_static_dir() {
  let assert Ok(priv_directory) = wisp.priv_directory("server")
  priv_directory <> "/static"
}

pub fn layout(
  children children: element.Element(a),
  session session: option.Option(context.Session),
  payload payload: option.Option(element.Element(a)),
) {
  html.html([], [
    html.head([], [
      html.link([
        attribute.href("/static/client.css"),
        attribute.rel("stylesheet"),
      ]),
      html.script(
        [attribute.src("/static/client.mjs"), attribute.type_("module")],
        "",
      ),
      theme.load_theme_script(),
      case session {
        option.None -> element.none()
        option.Some(session) -> {
          html.script(
            [
              attribute.type_("application/json"),
              attribute.id(context.session_hydration_key),
            ],
            context.encode_session(session),
          )
        }
      },
      case payload {
        option.None -> element.none()
        option.Some(payload) -> payload
      },
    ]),
    html.body([attribute.class("bg-surface text-on-surface mb-24 p-4")], [
      html.div([attribute.id("app")], [children]),
    ]),
  ])
}
