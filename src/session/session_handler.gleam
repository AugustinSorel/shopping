import app/error
import app/web
import auth/auth_service
import components/alert
import components/icon
import gleam/option
import gleam/result
import lustre/element
import lustre/element/html
import session/session_repo
import session/session_service
import wisp

pub fn create(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  let session_id = wisp.random_string(64)
  let secret = wisp.random_string(64)
  let secret_hash = auth_service.hash_secret(secret)

  let token = session_service.encode_token(session_id, secret)
  let user_id = 1

  let result = {
    let create = {
      session_repo.create(id: session_id, user_id:, secret_hash:, db: ctx.db)
    }

    use session <- result.try(create)

    Ok(session)
  }

  case result {
    Ok(_session) -> {
      wisp.ok() |> session_service.set_cookie(req, token)
    }
    Error(error.Internal(msg)) -> {
      alert.alert(alert.Destructive, [], [
        icon.circle_alert([]),
        alert.title([], [html.text("something went wrong!")]),
        alert.description([], [html.text(msg)]),
      ])
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
    Error(_e) -> {
      alert.alert(alert.Destructive, [], [
        icon.circle_alert([]),
        alert.title([], [html.text("something went wrong!")]),
        alert.description([], [html.text("something went wrong!")]),
      ])
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}

pub fn sign_out(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  let result = {
    let session = option.to_result(ctx.session, error.Unauthorized)

    use session <- result.try(session)

    let delete_session = session_repo.delete(session.id, ctx.db)

    use _ <- result.try(delete_session)

    Ok(session)
  }

  case result {
    Ok(_session) -> {
      wisp.ok() |> session_service.delete_cookie(req)
    }
    Error(error.Unauthorized) -> {
      wisp.redirect(to: "/auth/sign-up")
    }
    Error(error.Internal(msg)) -> {
      alert.alert(alert.Destructive, [], [
        icon.circle_alert([]),
        alert.title([], [html.text("something went wrong!")]),
        alert.description([], [html.text(msg)]),
      ])
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
    Error(_e) -> {
      alert.alert(alert.Destructive, [], [
        icon.circle_alert([]),
        alert.title([], [html.text("something went wrong!")]),
        alert.description([], [html.text("something went wrong!")]),
      ])
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}
