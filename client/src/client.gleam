import formal/form
import gleam/option
import gleam/uri
import icon
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import modem
import view

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Route {
  SignUp(form: form.Form)
  SignIn
  Products
  CreateProduct
  Account
  NotFound(uri: uri.Uri)
}

fn uri_to_route(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["sign-up"] -> SignUp(form: form.new())
    ["sign-in"] -> SignIn
    [] | [""] | ["products"] -> Products
    ["products", "create"] -> CreateProduct
    ["users", "account"] -> Account
    _ -> NotFound(uri:)
  }
}

type Model {
  Model(route: Route, user: option.Option(Nil))
}

fn init(_) {
  let route = case modem.initial_uri() {
    Ok(uri) -> uri_to_route(uri)
    Error(_) -> SignUp(form: form.new())
  }

  let model = Model(route:, user: option.None)

  let effect =
    modem.init(fn(uri) {
      uri
      |> uri_to_route
      |> UserNavigatedTo
    })

  #(model, effect)
}

type Msg {
  UserNavigatedTo(route: Route)
  UserSubmittedSignUpForm(form: List(#(String, String)))
}

fn update(model: Model, msg: Msg) {
  case msg {
    UserNavigatedTo(route:) -> {
      #(Model(..model, route:), effect.none())
    }
    UserSubmittedSignUpForm(form:) -> {
      case decode_sign_up_form(form) {
        Ok(SignUpData(..) as form) -> {
          echo form

          #(model, navigate_to(Products))
        }
        Error(form) -> {
          #(Model(..model, route: SignUp(form:)), effect.none())
        }
      }
    }
  }
}

fn navigate_to(route: Route) {
  effect.from(fn(dispatch) { dispatch(UserNavigatedTo(route:)) })
}

type SignUpData {
  SignUpData(email: String, password: String, confirm_password: String)
}

fn decode_sign_up_form(values: List(#(String, String))) {
  form.decoding({
    use email <- form.parameter
    use password <- form.parameter
    use confirm_password <- form.parameter

    SignUpData(email:, password:, confirm_password:)
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

fn view(model: Model) {
  case model.route {
    SignIn -> {
      html.h1([], [html.text("/sign-in")])
    }
    SignUp(form:) -> {
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
            event.on_submit(UserSubmittedSignUpForm),
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
                    [
                      attribute.class(
                        "text-error text-sm first-letter:capitalize",
                      ),
                    ],
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
                    [
                      attribute.class(
                        "text-error text-sm first-letter:capitalize",
                      ),
                    ],
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
                    [
                      attribute.class(
                        "text-error text-sm first-letter:capitalize",
                      ),
                    ],
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
    Account -> {
      html.h1([], [html.text("/users/account")])
    }
    CreateProduct -> {
      html.h1([], [html.text("/products/create")])
    }
    Products -> {
      html.h1([], [html.text("/products")])
    }
    NotFound(_uri) -> {
      html.h1([], [html.text("not found")])
    }
  }
}
