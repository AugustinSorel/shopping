import app/error
import app/web
import auth/auth_components
import auth/auth_service
import auth/auth_validator
import components/alert
import components/icon
import components/layout
import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/option
import gleam/result
import lustre/element
import lustre/element/html
import pog
import session/session_repo
import session/session_service
import user/user_repo
import valid
import wisp

pub fn sign_up_page(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use <- web.guest_only(ctx)

  auth_components.sign_up_form(option.None, option.None)
  |> auth_components.sign_up_page()
  |> layout.component(req.path, ctx)
  |> element.to_document_string_tree
  |> wisp.html_response(wisp.ok().status)
}

pub fn sign_up(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use <- web.guest_only(ctx)

  use formdata <- wisp.require_form(req)

  let input = {
    auth_validator.SignUpInput(
      email: list.key_find(formdata.values, "email") |> option.from_result,
      password: list.key_find(formdata.values, "password") |> option.from_result,
      confirm_password: list.key_find(formdata.values, "confirm_password")
        |> option.from_result,
    )
  }

  let validator = {
    input
    |> valid.validate(auth_validator.sign_up)
    |> result.map_error(fn(errors) {
      error.SignUpValidation(
        email: error.messages_for(auth_validator.Email, errors),
        password: error.messages_for(auth_validator.Password, errors),
        confirm_password: error.messages_for(
          auth_validator.ConfirmPassword,
          errors,
        ),
      )
    })
  }

  let result = {
    use user <- result.try(validator)

    let hashed_password = {
      user.password |> bit_array.from_string |> auth_service.hash_secret
    }

    let token = {
      pog.transaction(ctx.db, fn(db) {
        let user = user_repo.create(user.email, hashed_password, db)

        use user <- result.try(user)

        let session_id = wisp.random_string(64)
        let secret = wisp.random_string(64)
        let secret_hash = {
          secret |> bit_array.from_string |> auth_service.sha512_hash
        }

        let token = session_service.encode_token(session_id, secret)

        let session = session_repo.create(session_id, secret_hash, user.id, db)

        use _session <- result.try(session)

        Ok(token)
      })
      |> result.map_error(fn(e) {
        case e {
          pog.TransactionQueryError(_) -> {
            error.Internal(msg: "somehting went wrong")
          }
          pog.TransactionRolledBack(e) -> e
        }
      })
    }

    use token <- result.try(token)

    Ok(token)
  }

  case result {
    Ok(token) -> {
      wisp.ok()
      |> wisp.set_header("hx-redirect", "/")
      |> session_service.set_cookie(req, token)
    }
    Error(error.SignUpValidation(email, password, confirm_password)) -> {
      let errors = {
        auth_components.SignUpErrors(
          root: option.None,
          email:,
          password:,
          confirm_password:,
        )
      }

      let input = {
        auth_components.SignUpValues(
          email: input.email,
          password: input.password,
          confirm_password: input.confirm_password,
        )
      }

      auth_components.sign_up_form(option.Some(input), option.Some(errors))
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.unprocessable_entity().status)
    }
    Error(e) -> {
      let msg = case e {
        error.UserConflict -> "email already used"
        error.Internal(msg) -> msg
        _ -> "something went wrong"
      }

      let errors = {
        auth_components.SignUpErrors(
          root: option.Some(msg),
          email: option.None,
          password: option.None,
          confirm_password: option.None,
        )
      }

      let input = {
        auth_components.SignUpValues(
          email: input.email,
          password: input.password,
          confirm_password: input.confirm_password,
        )
      }

      auth_components.sign_up_form(option.Some(input), option.Some(errors))
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}

pub fn sign_in(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use <- web.guest_only(ctx)

  use formdata <- wisp.require_form(req)

  let input = {
    auth_validator.SignInInput(
      email: list.key_find(formdata.values, "email") |> option.from_result,
      password: list.key_find(formdata.values, "password") |> option.from_result,
    )
  }

  let validator = {
    input
    |> valid.validate(auth_validator.sign_in)
    |> result.map_error(fn(errors) {
      error.SignInValidation(
        email: error.messages_for(auth_validator.Email, errors),
        password: error.messages_for(auth_validator.Password, errors),
      )
    })
  }

  let result = {
    use candidate_user <- result.try(validator)

    let user = user_repo.get_by_email(candidate_user.email, ctx.db)

    use user <- result.try(user)

    let password_valid = {
      candidate_user.password
      |> bit_array.from_string
      |> auth_service.hash_verify(user.password)
    }

    use <- bool.guard(
      when: !password_valid,
      return: Error(error.InvalidCredentials),
    )

    let session_id = wisp.random_string(64)
    let secret = wisp.random_string(64)
    let secret_hash = {
      secret |> bit_array.from_string |> auth_service.sha512_hash
    }

    let token = session_service.encode_token(session_id, secret)

    let session = session_repo.create(session_id, secret_hash, user.id, ctx.db)

    use _session <- result.try(session)

    Ok(token)
  }

  case result {
    Ok(token) -> {
      wisp.ok()
      |> wisp.set_header("hx-redirect", "/")
      |> session_service.set_cookie(req, token)
    }
    Error(error.SignInValidation(email, password)) -> {
      let errors = {
        auth_components.SignInErrors(root: option.None, email:, password:)
      }

      let input = {
        auth_components.SignInValues(
          email: input.email,
          password: input.password,
        )
      }

      auth_components.sign_in_form(option.Some(input), option.Some(errors))
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.unprocessable_entity().status)
    }
    Error(e) -> {
      let msg = case e {
        error.Internal(msg) -> msg
        error.UserNotFound | error.InvalidCredentials -> {
          "email or password is incorrect"
        }
        _ -> "something went wrong"
      }

      let errors = {
        auth_components.SignInErrors(
          root: option.Some(msg),
          email: option.None,
          password: option.None,
        )
      }

      let input = {
        auth_components.SignInValues(
          email: input.email,
          password: input.password,
        )
      }

      auth_components.sign_in_form(option.Some(input), option.Some(errors))
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}

pub fn sign_in_page(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use <- web.guest_only(ctx)

  auth_components.sign_in_form(option.None, option.None)
  |> auth_components.sign_in_page()
  |> layout.component(req.path, ctx)
  |> element.to_document_string_tree
  |> wisp.html_response(wisp.ok().status)
}

pub fn sign_out(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use session <- web.auth_guard(ctx)

  let result = {
    let delete_session = session_repo.delete(session.id, ctx.db)

    use _ <- result.try(delete_session)

    Ok(Nil)
  }

  case result {
    Ok(_) -> {
      wisp.ok()
      |> wisp.set_header("hx-redirect", "/sign-in")
      |> session_service.delete_cookie(req)
    }
    Error(e) -> {
      let msg = case e {
        error.Internal(msg) -> msg
        _ -> "something went wrong"
      }

      alert.alert(alert.Destructive, [], [
        icon.circle_alert([]),
        alert.title([], [html.text(msg)]),
        alert.description([], [html.text("something went wrong!")]),
      ])
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}
