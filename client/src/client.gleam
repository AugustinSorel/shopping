import formal/form
import gleam/option
import gleam/string
import gleam/uri
import lustre
import lustre/effect
import lustre/element/html
import modem
import pages/sign_in
import pages/sign_up

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Route {
  SignUp(form: form.Form)
  SignIn(form: form.Form)
  Products
  CreateProduct
  Account
  NotFound(uri: uri.Uri)
}

fn uri_to_route(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["sign-up"] -> SignUp(form: form.new())
    ["sign-in"] -> SignIn(form: form.new())
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
  UserSubmittedSignInForm(form: List(#(String, String)))
}

fn update(model: Model, msg: Msg) {
  case msg {
    UserNavigatedTo(route:) -> {
      #(Model(..model, route:), effect.none())
    }
    UserSubmittedSignUpForm(form:) -> {
      case sign_up.decode_form(form) {
        Ok(sign_up.FormData(..) as form) -> {
          echo "TODO, make a request to /sign-up" <> string.inspect(form)

          #(model, navigate_to(Products))
        }
        Error(form) -> {
          #(Model(..model, route: SignUp(form:)), effect.none())
        }
      }
    }
    UserSubmittedSignInForm(form:) -> {
      case sign_up.decode_form(form) {
        Ok(sign_up.FormData(..) as form) -> {
          echo "TODO, make a request to /sign-in" <> string.inspect(form)

          #(model, navigate_to(Products))
        }
        Error(form) -> {
          #(Model(..model, route: SignIn(form:)), effect.none())
        }
      }
    }
  }
}

fn navigate_to(route: Route) {
  effect.from(fn(dispatch) { dispatch(UserNavigatedTo(route:)) })
}

fn view(model: Model) {
  case model.route {
    SignIn(form:) -> {
      sign_in.view(form:, on_submit: UserSubmittedSignInForm)
    }
    SignUp(form:) -> {
      sign_up.view(form:, on_submit: UserSubmittedSignUpForm)
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
