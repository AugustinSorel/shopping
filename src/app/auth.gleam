import antigone
import app/error
import app/icon
import app/session
import app/user
import app/validator
import app/view
import app/web
import gleam/bit_array
import gleam/bool
import gleam/option
import gleam/order
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import pog
import valid
import wisp

fn hash_secret(secret: BitArray) {
  antigone.hash(antigone.hasher(), secret)
}

fn hash_verify(left: BitArray, right: String) {
  antigone.verify(left, right)
}

pub fn sign_up_page(children: element.Element(msg)) {
  html.main([attribute.class("max-w-app mx-auto py-10 space-y-15")], [
    html.h1(
      [
        attribute.class(
          "text-2xl font-semibold first-letter:capitalize text-center",
        ),
      ],
      [html.text("welcome")],
    ),
    children,
    html.p([attribute.class("text-secondary text-sm text-center")], [
      html.text("already got an account? "),
      html.a([attribute.href("/sign-in")], [
        html.span([attribute.class("text-primary hover:underline")], [
          html.text("sign-in"),
        ]),
      ]),
    ]),
  ])
}

pub type SignUpValues {
  SignUpValues(
    email: option.Option(String),
    password: option.Option(String),
    confirm_password: option.Option(String),
  )
}

pub type SignUpErrors {
  SignUpErrors(
    root: option.Option(String),
    email: option.Option(List(String)),
    password: option.Option(List(String)),
    confirm_password: option.Option(List(String)),
  )
}

pub fn sign_up_form(
  values: option.Option(SignUpValues),
  errors: option.Option(SignUpErrors),
) {
  html.form(
    [
      attribute.attribute("hx-post", "/sign-up"),
      attribute.attribute("hx-target", "this"),
      attribute.attribute("hx-swap", "outerHTML"),
      attribute.attribute("hx-disabled-elt", "find button[type='submit']"),
      attribute.class("flex flex-col gap-5"),
    ],
    [
      html.label([attribute.class("flex flex-col gap-1")], [
        html.span([attribute.class("first-letter:capitalize")], [
          html.text("email:"),
        ]),
        view.input([
          attribute.placeholder("john@example.com"),
          attribute.type_("email"),
          attribute.name("email"),
          case values {
            option.Some(SignUpValues(email: option.Some(email), ..)) -> {
              attribute.value(email)
            }
            _ -> attribute.none()
          },
        ]),
        case errors {
          option.Some(SignUpErrors(email: option.Some([e, ..]), ..)) -> {
            html.p(
              [attribute.class("text-error text-sm first-letter:capitalize")],
              [html.text(e)],
            )
          }
          _ -> element.none()
        },
      ]),
      html.label([attribute.class("flex flex-col gap-1")], [
        html.span([attribute.class("first-letter:capitalize")], [
          html.text("password:"),
        ]),
        view.input([
          attribute.placeholder("****"),
          attribute.type_("password"),
          attribute.name("password"),
          case values {
            option.Some(SignUpValues(password: option.Some(password), ..)) -> {
              attribute.value(password)
            }
            _ -> attribute.none()
          },
        ]),
        case errors {
          option.Some(SignUpErrors(password: option.Some([e, ..]), ..)) -> {
            html.p(
              [attribute.class("text-error text-sm first-letter:capitalize")],
              [html.text(e)],
            )
          }
          _ -> element.none()
        },
      ]),
      html.label([attribute.class("flex flex-col gap-1")], [
        html.span([attribute.class("first-letter:capitalize")], [
          html.text("confirm password:"),
        ]),
        view.input([
          attribute.placeholder("****"),
          attribute.type_("password"),
          attribute.name("confirm_password"),
          case values {
            option.Some(SignUpValues(
              confirm_password: option.Some(confirm_password),
              ..,
            )) -> {
              attribute.value(confirm_password)
            }
            _ -> attribute.none()
          },
        ]),
        case errors {
          option.Some(SignUpErrors(confirm_password: option.Some([e, ..]), ..)) -> {
            html.p(
              [attribute.class("text-error text-sm first-letter:capitalize")],
              [html.text(e)],
            )
          }
          _ -> element.none()
        },
      ]),
      view.button(view.Default, view.Medium, [attribute.type_("submit")], [
        html.text("sign up"),
        view.spinner([], icon.Small),
      ]),
      case errors {
        option.Some(SignUpErrors(root: option.Some(e), ..)) -> {
          view.alert(view.Destructive, [], [
            icon.circle_alert([]),
            view.alert_title([], [html.text("something went wrong!")]),
            view.alert_description([], [html.text(e)]),
          ])
        }
        _ -> element.none()
      },
    ],
  )
}

pub type SignInValues {
  SignInValues(email: option.Option(String), password: option.Option(String))
}

pub type SignInErrors {
  SignInErrors(
    root: option.Option(String),
    email: option.Option(List(String)),
    password: option.Option(List(String)),
  )
}

pub fn sign_in_page(children: element.Element(msg)) {
  html.main([attribute.class("max-w-app mx-auto py-10 space-y-15")], [
    html.h1(
      [
        attribute.class(
          "text-2xl font-semibold first-letter:capitalize text-center",
        ),
      ],
      [html.text("welcome back!")],
    ),
    children,
    html.p([attribute.class("text-secondary text-sm text-center")], [
      html.text("don't have an account? "),
      html.a([attribute.href("/sign-up")], [
        html.span([attribute.class("text-primary hover:underline")], [
          html.text("sign-up"),
        ]),
      ]),
    ]),
  ])
}

pub fn sign_in_form(
  values: option.Option(SignInValues),
  errors: option.Option(SignInErrors),
) {
  html.form(
    [
      attribute.attribute("hx-post", "/sign-in"),
      attribute.attribute("hx-target", "this"),
      attribute.attribute("hx-swap", "outerHTML"),
      attribute.attribute("hx-disabled-elt", "find button[type='submit']"),
      attribute.class("flex flex-col gap-5"),
    ],
    [
      html.label([attribute.class("flex flex-col gap-1")], [
        html.span([attribute.class("first-letter:capitalize")], [
          html.text("email:"),
        ]),
        view.input([
          attribute.placeholder("john@example.com"),
          attribute.type_("email"),
          attribute.name("email"),
          case values {
            option.Some(SignInValues(email: option.Some(email), ..)) -> {
              attribute.value(email)
            }
            _ -> attribute.none()
          },
        ]),
        case errors {
          option.Some(SignInErrors(email: option.Some([e, ..]), ..)) -> {
            html.p(
              [attribute.class("text-error text-sm first-letter:capitalize")],
              [html.text(e)],
            )
          }
          _ -> element.none()
        },
      ]),
      html.label([attribute.class("flex flex-col gap-1")], [
        html.span([attribute.class("first-letter:capitalize")], [
          html.text("password:"),
        ]),
        view.input([
          attribute.placeholder("****"),
          attribute.type_("password"),
          attribute.name("password"),
          case values {
            option.Some(SignInValues(password: option.Some(password), ..)) -> {
              attribute.value(password)
            }
            _ -> attribute.none()
          },
        ]),
        case errors {
          option.Some(SignInErrors(password: option.Some([e, ..]), ..)) -> {
            html.p(
              [attribute.class("text-error text-sm first-letter:capitalize")],
              [html.text(e)],
            )
          }
          _ -> element.none()
        },
      ]),
      view.button(view.Default, view.Medium, [attribute.type_("submit")], [
        html.text("sign in"),
        view.spinner([], icon.Small),
      ]),
      case errors {
        option.Some(SignInErrors(root: option.Some(e), ..)) -> {
          view.alert(view.Destructive, [], [
            icon.circle_alert([]),
            view.alert_title([], [html.text("something went wrong!")]),
            view.alert_description([], [html.text(e)]),
          ])
        }
        _ -> element.none()
      },
    ],
  )
}

pub fn sign_up(user: SignUpOutput, ctx: web.Ctx) {
  let hashed_password = {
    user.password |> bit_array.from_string |> hash_secret
  }

  let token = {
    pog.transaction(ctx.db, fn(db) {
      let user = user.create(user.email, hashed_password, db)

      use user <- result.try(user)

      let session_id = wisp.random_string(64)
      let secret = wisp.random_string(64)
      let secret_hash = {
        secret |> bit_array.from_string |> session.sha512_hash
      }

      let token = session.encode_token(session_id, secret)

      let session = session.create(session_id, secret_hash, user.id, db)

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

pub fn sign_in(candidate_user: SignInOutput, ctx: web.Ctx) {
  let user = user.get_by_email(candidate_user.email, ctx.db)

  use user <- result.try(user)

  let password_valid = {
    candidate_user.password
    |> bit_array.from_string
    |> hash_verify(user.password)
  }

  use <- bool.guard(
    when: !password_valid,
    return: Error(error.InvalidCredentials),
  )

  let session_id = wisp.random_string(64)
  let secret = wisp.random_string(64)
  let secret_hash = {
    secret |> bit_array.from_string |> session.sha512_hash
  }

  let token = session.encode_token(session_id, secret)

  let session = session.create(session_id, secret_hash, user.id, ctx.db)

  use _session <- result.try(session)

  Ok(token)
}

pub type Fields {
  Email
  Password
  ConfirmPassword
}

fn validate_email() {
  let error = fn(msg) { #(Email, msg) }

  validator.trim
  |> valid.then(valid.string_is_not_empty(error("email is required")))
  |> valid.then(valid.string_is_email(error("email must be valid")))
  |> valid.then(valid.string_min_length(
    3,
    error("email must be at least 3 characters"),
  ))
  |> valid.then(valid.string_max_length(
    255,
    error("email must be at most 255 characters"),
  ))
  |> validator.string_required(error("email is required"))
}

fn validate_password() {
  let error = fn(msg) { #(Password, msg) }

  validator.trim
  |> valid.then(valid.string_is_not_empty(error("password is required")))
  |> valid.then(valid.string_min_length(
    3,
    error("password must be at least 3 characters"),
  ))
  |> valid.then(valid.string_max_length(
    255,
    error("password must be at most 255 characters"),
  ))
  |> validator.string_required(error("password is required"))
}

fn confirm_password(password: String) {
  fn(confirm_password: option.Option(String)) {
    let confirm_password = option.unwrap(confirm_password, "")

    case string.compare(password, confirm_password) {
      order.Eq -> #(password, [])
      _ -> #(password, [#(ConfirmPassword, "password don't match")])
    }
  }
}

pub type SignUpOutput {
  SignUpOutput(email: String, password: String, confirm_password: String)
}

pub fn validate_sign_up(input: SignUpValues) {
  input
  |> valid.validate(fn(input) {
    use email <- valid.check(input.email, validate_email())
    use password <- valid.check(input.password, validate_password())
    use confirm_password <- valid.check(
      input.confirm_password,
      confirm_password(password),
    )

    valid.ok(SignUpOutput(email:, password:, confirm_password:))
  })
  |> result.map_error(fn(errors) {
    error.SignUpValidation(
      email: error.messages_for(Email, errors),
      password: error.messages_for(Password, errors),
      confirm_password: error.messages_for(ConfirmPassword, errors),
    )
  })
}

pub type SignInOutput {
  SignInOutput(email: String, password: String)
}

pub fn validate_sign_in(input: SignInValues) {
  input
  |> valid.validate(fn(input) {
    use email <- valid.check(input.email, validate_email())
    use password <- valid.check(input.password, validate_password())

    valid.ok(SignInOutput(email:, password:))
  })
  |> result.map_error(fn(errors) {
    error.SignInValidation(
      email: error.messages_for(Email, errors),
      password: error.messages_for(Password, errors),
    )
  })
}
