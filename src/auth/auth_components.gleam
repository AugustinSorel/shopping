import app/icon
import app/view
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html

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
