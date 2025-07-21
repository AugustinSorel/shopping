import formal/form
import gleam/http/response
import gleam/option
import gleam/uri
import lustre
import lustre/effect
import lustre/element/html
import modem
import network
import pages/sign_in
import pages/sign_up
import rsvp
import shared/auth

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Route {
  SignUp(form: form.Form, state: network.State(Nil))
  SignIn(form: form.Form, state: network.State(Nil))
  Products
  CreateProduct
  Account
  NotFound(uri: uri.Uri)
}

pub fn uri_to_route(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["sign-up"] -> SignUp(form: form.new(), state: network.Idle)
    ["sign-in"] -> SignIn(form: form.new(), state: network.Idle)
    [] | [""] | ["products"] -> Products
    ["products", "create"] -> CreateProduct
    ["users", "account"] -> Account
    _ -> NotFound(uri:)
  }
}

pub type Model {
  Model(route: Route, user: option.Option(Nil))
}

fn init(_) {
  let route = case modem.initial_uri() {
    Ok(uri) -> uri_to_route(uri)
    Error(_) -> SignUp(form: form.new(), state: network.Idle)
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

pub type Msg {
  UserNavigatedTo(route: Route)
  UserSubmittedSignUpForm(form: List(#(String, String)))
  UserSubmittedSignInForm(form: List(#(String, String)))
  ApiReturnedSignUp(Result(response.Response(String), rsvp.Error))
  ApiReturnedSignIn(Result(response.Response(String), rsvp.Error))
}

fn update(model: Model, msg: Msg) {
  case model.route, msg {
    _, UserNavigatedTo(route:) -> {
      #(Model(..model, route:), effect.none())
    }
    SignUp(..) as sign_up, UserSubmittedSignUpForm(form:) -> {
      case sign_up.decode_form(form) {
        Ok(auth.SignUpInput(..) as form) -> {
          #(
            Model(..model, route: SignUp(..sign_up, state: network.Loading)),
            sign_up.sign_up(form, ApiReturnedSignUp),
          )
        }
        Error(form) -> {
          #(
            Model(..model, route: SignUp(form:, state: network.Idle)),
            effect.none(),
          )
        }
      }
    }
    SignIn(..) as sign_in, UserSubmittedSignInForm(form:) -> {
      case sign_in.decode_form(form) {
        Ok(auth.SignInInput(..) as form) -> {
          #(
            Model(..model, route: SignIn(..sign_in, state: network.Loading)),
            sign_in.sign_in(form, ApiReturnedSignIn),
          )
        }
        Error(form) -> {
          #(
            Model(..model, route: SignIn(form:, state: network.Idle)),
            effect.none(),
          )
        }
      }
    }
    SignUp(..) as sign_up, ApiReturnedSignUp(Ok(_)) -> {
      #(
        Model(..model, route: SignUp(..sign_up, state: network.Success(Nil))),
        navigate(to: Products),
      )
    }
    SignUp(..) as sign_up, ApiReturnedSignUp(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      #(
        Model(..model, route: SignUp(..sign_up, state: network.Err(msg:))),
        effect.none(),
      )
    }
    SignIn(..) as sign_in, ApiReturnedSignIn(Ok(_)) -> {
      #(
        Model(..model, route: SignIn(..sign_in, state: network.Success(Nil))),
        navigate(to: Products),
      )
    }
    SignIn(..) as sign_in, ApiReturnedSignIn(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      #(
        Model(..model, route: SignIn(..sign_in, state: network.Err(msg:))),
        effect.none(),
      )
    }
    _, _ -> {
      #(model, effect.none())
    }
  }
}

fn navigate(to route: Route) {
  effect.from(fn(dispatch) { dispatch(UserNavigatedTo(route:)) })
}

pub fn view(model: Model) {
  case model.route {
    SignIn(form:, state:) -> {
      sign_in.view(form:, state:, on_submit: UserSubmittedSignInForm)
    }
    SignUp(form:, state:) -> {
      sign_up.view(form:, state:, on_submit: UserSubmittedSignUpForm)
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
