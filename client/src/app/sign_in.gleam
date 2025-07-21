import app/icon
import app/network
import app/view
import formal/form
import gleam/json
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import shared/auth

pub fn sign_in(body: auth.SignInInput, handle_response) {
  let body =
    json.object([
      #("email", json.string(body.email)),
      #("password", json.string(body.password)),
    ])

  rsvp.post("/sign-in", body, rsvp.expect_ok_response(handle_response))
}

pub fn decode_form(values: List(#(String, String))) {
  form.decoding({
    use email <- form.parameter
    use password <- form.parameter

    auth.SignInInput(email:, password:)
  })
  |> form.with_values(values)
  |> form.field(
    "email",
    form.string
      |> form.and(
        form.must_be_an_email
        |> form.message("email must be valid"),
      )
      |> form.and(
        form.must_not_be_empty
        |> form.message("email cannot be blank"),
      )
      |> form.and(
        form.must_be_string_longer_than(3)
        |> form.message("email must be at least 3 characters"),
      )
      |> form.and(
        form.must_be_string_shorter_than(255)
        |> form.message("email must be at most 255 characters"),
      ),
  )
  |> form.field(
    "password",
    form.string
      |> form.and(
        form.must_not_be_empty
        |> form.message("password cannot be blank"),
      )
      |> form.and(
        form.must_be_string_longer_than(3)
        |> form.message("password must be at least 3 characters"),
      )
      |> form.and(
        form.must_be_string_shorter_than(255)
        |> form.message("password must be at most 255 characters"),
      ),
  )
  |> form.finish
}

pub fn view(
  form form: form.Form,
  state state: network.State(a),
  on_submit on_submit,
) {
  html.main([attribute.class("max-w-app mx-auto py-10 space-y-15")], [
    html.h1(
      [
        attribute.class(
          "text-2xl font-semibold first-letter:capitalize text-center",
        ),
      ],
      [html.text("welcome back!")],
    ),
    html.form(
      [
        attribute.attribute("hx-post", "/sign-up"),
        attribute.attribute("hx-target", "this"),
        attribute.attribute("hx-swap", "outerHTML"),
        attribute.attribute("hx-disabled-elt", "find button[type='submit']"),
        attribute.class("flex flex-col gap-5"),
        event.on_submit(on_submit),
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
          ]),
          case form.field_state(form, "email") {
            Ok(_) -> element.none()
            Error(e) -> {
              html.p(
                [attribute.class("text-error text-sm first-letter:capitalize")],
                [html.text(e)],
              )
            }
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
          ]),
          case form.field_state(form, "password") {
            Ok(_) -> element.none()
            Error(e) -> {
              html.p(
                [attribute.class("text-error text-sm first-letter:capitalize")],
                [html.text(e)],
              )
            }
          },
        ]),
        case state {
          network.Err(msg:) -> {
            view.alert(view.Destructive, [], [
              icon.circle_alert([]),
              view.alert_title([], [html.text("something went wrong")]),
              view.alert_description([], [html.text(msg)]),
            ])
          }
          _ -> element.none()
        },
        view.button(
          view.Default,
          view.Medium,
          [
            attribute.type_("submit"),
            attribute.disabled(case state {
              network.Loading -> True
              _ -> False
            }),
          ],
          [
            html.text("sign in"),
            case state {
              network.Loading -> view.spinner([], icon.Small)
              _ -> element.none()
            },
          ],
        ),
      ],
    ),
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
