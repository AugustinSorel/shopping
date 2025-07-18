import formal/form
import icon
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import view

pub type FormData {
  FormData(email: String, password: String, confirm_password: String)
}

pub fn decode_form(values: List(#(String, String))) {
  form.decoding({
    use email <- form.parameter
    use password <- form.parameter
    use confirm_password <- form.parameter

    FormData(email:, password:, confirm_password:)
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
  |> form.field(
    "confirm_password",
    form.string
      |> form.and(
        form.must_not_be_empty
        |> form.message("confirm password cannot be blank"),
      )
      |> form.and(
        form.must_be_string_longer_than(3)
        |> form.message("confirm password must be at least 3 characters"),
      )
      |> form.and(
        form.must_be_string_shorter_than(255)
        |> form.message("confirm password must be at most 255 characters"),
      )
      |> form.and(form.must_equal(
        form.value(form.initial_values(values), "password"),
        because: "password and confirm password don't match",
      )),
  )
  |> form.finish
}

pub fn view(form form: form.Form, on_submit on_submit) {
  html.main([attribute.class("max-w-app mx-auto py-10 space-y-15")], [
    html.h1(
      [
        attribute.class(
          "text-2xl font-semibold first-letter:capitalize text-center",
        ),
      ],
      [html.text("welcome")],
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
        html.label([attribute.class("flex flex-col gap-1")], [
          html.span([attribute.class("first-letter:capitalize")], [
            html.text("confirm password:"),
          ]),
          view.input([
            attribute.placeholder("****"),
            attribute.type_("password"),
            attribute.name("confirm_password"),
          ]),
          case form.field_state(form, "confirm_password") {
            Ok(_) -> element.none()
            Error(e) -> {
              html.p(
                [attribute.class("text-error text-sm first-letter:capitalize")],
                [html.text(e)],
              )
            }
          },
        ]),
        //TODO:ROOT
        view.button(view.Default, view.Medium, [attribute.type_("submit")], [
          html.text("sign up"),
          view.spinner([], icon.Small),
        ]),
      ],
    ),
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
