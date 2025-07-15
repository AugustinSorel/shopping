import app/auth
import app/error
import app/icon
import app/product
import app/session
import app/user
import app/view
import app/web
import gleam/http
import gleam/list
import gleam/option
import gleam/result
import lustre/element
import lustre/element/html
import wisp

pub fn handle_request(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use req <- web.middleware(req)

  let session =
    req
    |> session.get_cookie()
    |> result.unwrap("")
    |> session.validate(ctx)
    |> option.from_result

  let ctx = web.Ctx(..ctx, session:)

  case wisp.path_segments(req) {
    [] -> wisp.redirect(to: "/products")

    ["products"] -> products(req, ctx)
    ["products", "create"] -> products_create(req, ctx)
    ["products", product_id, "bought"] -> product_bought(req, ctx, product_id)

    ["sign-up"] -> sign_up(req, ctx)
    ["sign-in"] -> sign_in(req, ctx)
    ["sign-out"] -> sign_out(req, ctx)

    ["users", "account"] -> users_account(req, ctx)

    _ -> wisp.not_found()
  }
}

fn users_account(req: wisp.Request, ctx: web.Ctx) {
  use <- wisp.require_method(req, http.Get)

  use session <- web.auth_guard(ctx)

  let result = {
    let stats = product.get_stats(session.user.id, ctx.db)

    use stats <- result.try(stats)

    Ok(stats)
  }

  case result {
    Ok(stats) -> {
      [product.stats(stats), user.preference()]
      |> user.account_page(session.user)
      |> view.layout(req.path, ctx)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
    }
    Error(e) -> {
      let msg = case e {
        error.Internal(msg:) -> msg
        _ -> "something went wrong"
      }

      [product.stats_fallback(msg), user.preference_fallback(msg)]
      |> user.account_page(session.user)
      |> view.layout(req.path, ctx)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}

fn sign_up(req: wisp.Request, ctx: web.Ctx) {
  use <- web.guest_only(ctx)

  case req.method {
    http.Get -> {
      auth.sign_up_form(option.None, option.None)
      |> auth.sign_up_page()
      |> view.layout(req.path, ctx)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
    }
    http.Post -> {
      use formdata <- wisp.require_form(req)

      let input = {
        auth.SignUpValues(
          email: list.key_find(formdata.values, "email") |> option.from_result,
          password: list.key_find(formdata.values, "password")
            |> option.from_result,
          confirm_password: list.key_find(formdata.values, "confirm_password")
            |> option.from_result,
        )
      }

      let result = {
        use user <- result.try(auth.validate_sign_up(input))

        auth.sign_up(user, ctx)
      }

      case result {
        Ok(token) -> {
          wisp.ok()
          |> wisp.set_header("hx-redirect", "/")
          |> session.set_cookie(req, token)
        }
        Error(error.SignUpValidation(email, password, confirm_password)) -> {
          let errors = {
            auth.SignUpErrors(
              root: option.None,
              email:,
              password:,
              confirm_password:,
            )
          }

          auth.sign_up_form(option.Some(input), option.Some(errors))
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
            auth.SignUpErrors(
              root: option.Some(msg),
              email: option.None,
              password: option.None,
              confirm_password: option.None,
            )
          }

          auth.sign_up_form(option.Some(input), option.Some(errors))
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.internal_server_error().status)
        }
      }
    }

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn sign_in(req: wisp.Request, ctx: web.Ctx) {
  use <- web.guest_only(ctx)

  case req.method {
    http.Get -> {
      auth.sign_in_form(option.None, option.None)
      |> auth.sign_in_page()
      |> view.layout(req.path, ctx)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
    }
    http.Post -> {
      use <- web.guest_only(ctx)

      use formdata <- wisp.require_form(req)

      let input = {
        auth.SignInValues(
          email: list.key_find(formdata.values, "email") |> option.from_result,
          password: list.key_find(formdata.values, "password")
            |> option.from_result,
        )
      }

      let result = {
        use user <- result.try(auth.validate_sign_in(input))

        auth.sign_in(user, ctx)
      }

      case result {
        Ok(token) -> {
          wisp.ok()
          |> wisp.set_header("hx-redirect", "/")
          |> session.set_cookie(req, token)
        }
        Error(error.SignInValidation(email, password)) -> {
          let errors = {
            auth.SignInErrors(root: option.None, email:, password:)
          }

          auth.sign_in_form(option.Some(input), option.Some(errors))
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
            auth.SignInErrors(
              root: option.Some(msg),
              email: option.None,
              password: option.None,
            )
          }

          auth.sign_in_form(option.Some(input), option.Some(errors))
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.internal_server_error().status)
        }
      }
    }

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn sign_out(req: wisp.Request, ctx: web.Ctx) {
  use <- wisp.require_method(req, http.Post)

  use session <- web.auth_guard(ctx)

  let result = {
    let delete_session = session.delete(session.id, ctx.db)

    use _ <- result.try(delete_session)

    Ok(Nil)
  }

  case result {
    Ok(_) -> {
      wisp.ok()
      |> wisp.set_header("hx-redirect", "/sign-in")
      |> session.delete_cookie(req)
    }
    Error(e) -> {
      let msg = case e {
        error.Internal(msg) -> msg
        _ -> "something went wrong"
      }

      view.alert(view.Destructive, [], [
        icon.circle_alert([]),
        view.alert_title([], [html.text(msg)]),
        view.alert_description([], [html.text("something went wrong!")]),
      ])
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.internal_server_error().status)
    }
  }
}

fn products_create(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  use _session <- web.auth_guard(ctx)

  case req.method {
    http.Get -> {
      product.create_page()
      |> view.layout(req.path, ctx)
      |> element.to_document_string_tree
      |> wisp.html_response(wisp.ok().status)
    }

    _ -> wisp.method_not_allowed([http.Get])
  }
}

fn products(req: wisp.Request, ctx: web.Ctx) -> wisp.Response {
  case req.method {
    http.Get -> {
      use _session <- web.auth_guard(ctx)

      let result = product.get_by_purchase_status(ctx)

      case result {
        Ok(product.ProductsByStatus(purchased, unpurchased)) -> {
          product.by_purchased_status(purchased, unpurchased)
          |> product.by_purchased_status_page
          |> view.layout(req.path, ctx)
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.ok().status)
        }
        Error(e) -> {
          case e {
            error.Internal(msg) -> msg
            _ -> "something went wrong"
          }
          |> product.by_purchase_status_fallback
          |> product.by_purchased_status_page
          |> view.layout(req.path, ctx)
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.internal_server_error().status)
        }
      }
    }
    http.Post -> {
      use session <- web.auth_guard(ctx)

      use formdata <- wisp.require_form(req)

      let input = {
        product.CreateProductInput(
          title: list.key_find(formdata.values, "title") |> option.from_result,
          quantity: list.key_find(formdata.values, "quantity")
            |> option.from_result,
          location: list.key_find(formdata.values, "location")
            |> option.from_result,
          urgent: list.key_find(formdata.values, "urgent") |> option.from_result,
        )
      }

      let result = {
        use product <- result.try(product.validate_create(input))

        use product <- result.try(product.create(
          ctx.db,
          product.title,
          product.quantity,
          product.location,
          product.urgent,
          session.user.id,
        ))

        Ok(product)
      }

      case result {
        Ok(_product) -> {
          wisp.created()
          |> wisp.set_header("hx-redirect", "/products")
        }
        Error(error.ProductValidation(
          title:,
          quantity:,
          location:,
          urgent:,
          ..,
        )) -> {
          let errors = {
            product.CreateProductErrors(
              root: option.None,
              title:,
              quantity:,
              location:,
              urgent:,
            )
          }

          product.create_form(option.Some(input), option.Some(errors))
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.unprocessable_entity().status)
        }
        Error(e) -> {
          let msg = case e {
            error.Internal(msg) -> msg
            _ -> "something went wrong"
          }

          let errors = {
            product.CreateProductErrors(
              root: option.Some(msg),
              title: option.None,
              quantity: option.None,
              location: option.None,
              urgent: option.None,
            )
          }

          product.create_form(option.Some(input), option.Some(errors))
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.unprocessable_entity().status)
        }
      }
    }

    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
}

fn product_bought(
  req: wisp.Request,
  ctx: web.Ctx,
  product_id: String,
) -> wisp.Response {
  case req.method {
    http.Post -> {
      use _session <- web.auth_guard(ctx)

      let result = {
        use product_id <- result.try(product.validate_id_str(product_id))

        use _product <- result.try(product.create_bought_at(ctx.db, product_id))

        use products <- result.try(product.get_by_purchase_status(ctx))

        Ok(products)
      }

      case result {
        Ok(product.ProductsByStatus(purchased, unpurchased)) -> {
          product.by_purchased_status(purchased, unpurchased)
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.ok().status)
          |> wisp.set_header("hx-retarget", "main")
          |> wisp.set_header("hx-reswap", "outerHTML")
        }
        Error(e) -> {
          case e {
            error.Internal(msg) -> msg
            _ -> "something went wrong"
          }
          |> product.item_fallback()
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.internal_server_error().status)
        }
      }
    }
    http.Delete -> {
      use _session <- web.auth_guard(ctx)

      let result = {
        use product_id <- result.try(product.validate_id_str(product_id))

        use _product <- result.try(product.delete_bought_at(ctx.db, product_id))

        use products <- result.try(product.get_by_purchase_status(ctx))

        Ok(products)
      }

      case result {
        Ok(product.ProductsByStatus(purchased, unpurchased)) -> {
          product.by_purchased_status(purchased, unpurchased)
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.ok().status)
          |> wisp.set_header("hx-retarget", "main")
          |> wisp.set_header("hx-reswap", "outerHTML")
        }
        Error(e) -> {
          case e {
            error.Internal(msg) -> msg
            _ -> "something went wrong"
          }
          |> product.item_fallback()
          |> element.to_document_string_tree
          |> wisp.html_response(wisp.internal_server_error().status)
        }
      }
    }

    _ -> wisp.method_not_allowed([http.Delete, http.Post])
  }
}
