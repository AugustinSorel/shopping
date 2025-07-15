import app/error
import app/view
import app/web
import gleam/result
import lustre/element
import product/product_components
import product/product_repo
import user/user_components
import wisp

pub fn account_page(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use session <- web.auth_guard(ctx)

  let result = {
    let stats = product_repo.get_stats(session.user.id, ctx.db)

    use stats <- result.try(stats)

    Ok(stats)
  }

  case result {
    Ok(stats) -> {
      [product_components.stats(stats), user_components.preference()]
      |> user_components.account_page(session.user)
      |> view.layout(req.path, ctx)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
    }
    Error(e) -> {
      let msg = case e {
        error.Internal(msg:) -> msg
        _ -> "something went wrong"
      }

      [
        product_components.stats_fallback(msg),
        user_components.preference_fallback(msg),
      ]
      |> user_components.account_page(session.user)
      |> view.layout(req.path, ctx)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}
