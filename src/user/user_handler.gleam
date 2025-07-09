import app/web
import components/layout
import lustre/element
import user/user_components
import wisp

pub fn account_page(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use session <- web.auth_guard(ctx)

  [user_components.fun_facts(), user_components.preference()]
  |> user_components.account_page(session.user)
  |> layout.component(req.path, ctx)
  |> element.to_document_string_tree
  |> wisp.html_response(wisp.ok().status)
}
