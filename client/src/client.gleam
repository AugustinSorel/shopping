import client/auth
import client/network
import formal/form
import gleam/http/response
import gleam/uri
import lustre
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import modem
import rsvp
import shared/auth as shared_auth

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
  Model(route: Route)
}

fn init(_: a) -> #(Model, effect.Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> uri_to_route(uri)
    Error(_) -> SignUp(form: form.new(), state: network.Idle)
  }

  let model = Model(route:)

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
  UserClickedSignOut
  ApiReturnedSignUp(Result(response.Response(String), rsvp.Error))
  ApiReturnedSignIn(Result(response.Response(String), rsvp.Error))
  ApiReturnedSignOut(Result(response.Response(String), rsvp.Error))
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case model.route, msg {
    _, UserNavigatedTo(route:) -> {
      #(Model(route:), effect.none())
    }
    SignUp(..) as sign_up, UserSubmittedSignUpForm(form:) -> {
      case auth.decode_sign_up_form(form) {
        Ok(shared_auth.SignUpInput(..) as form) -> {
          #(
            Model(route: SignUp(..sign_up, state: network.Loading)),
            auth.sign_up_post(form, ApiReturnedSignUp),
          )
        }
        Error(form) -> {
          #(Model(route: SignUp(form:, state: network.Idle)), effect.none())
        }
      }
    }
    SignIn(..) as sign_in, UserSubmittedSignInForm(form:) -> {
      case auth.decode_sign_in_form(form) {
        Ok(shared_auth.SignInInput(..) as form) -> {
          #(
            Model(route: SignIn(..sign_in, state: network.Loading)),
            auth.sign_in_post(form, ApiReturnedSignIn),
          )
        }
        Error(form) -> {
          #(Model(route: SignIn(form:, state: network.Idle)), effect.none())
        }
      }
    }
    SignUp(..) as sign_up, ApiReturnedSignUp(Ok(_)) -> {
      #(
        Model(route: SignUp(..sign_up, state: network.Success(Nil))),
        navigate(to: Products),
      )
    }
    SignUp(..) as sign_up, ApiReturnedSignUp(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      #(
        Model(route: SignUp(..sign_up, state: network.Err(msg:))),
        effect.none(),
      )
    }
    SignIn(..) as sign_in, ApiReturnedSignIn(Ok(_)) -> {
      #(
        Model(route: SignIn(..sign_in, state: network.Success(Nil))),
        navigate(to: Products),
      )
    }
    SignIn(..) as sign_in, ApiReturnedSignIn(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      #(
        Model(route: SignIn(..sign_in, state: network.Err(msg:))),
        effect.none(),
      )
    }
    _, ApiReturnedSignOut(Ok(_)) -> {
      #(model, navigate(to: SignUp(form: form.new(), state: network.Idle)))
    }
    _, ApiReturnedSignOut(Error(_)) -> {
      #(model, effect.none())
    }
    _, UserClickedSignOut -> {
      #(model, auth.sign_out_post(ApiReturnedSignOut))
    }

    _, _ -> {
      #(model, effect.none())
    }
  }
}

fn navigate(to route: Route) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) { dispatch(UserNavigatedTo(route:)) })
}

pub fn view(model: Model) -> element.Element(Msg) {
  case model.route {
    SignIn(form:, state:) -> {
      auth.sign_in_view(form:, state:, on_submit: UserSubmittedSignInForm)
    }
    SignUp(form:, state:) -> {
      auth.sign_up_view(form:, state:, on_submit: UserSubmittedSignUpForm)
    }
    Account -> {
      html.h1([], [html.text("/users/account")])
    }
    CreateProduct -> {
      html.h1([], [html.text("/products/create")])
    }
    Products -> {
      html.h1([], [
        html.text("/products"),
        html.button([event.on_click(UserClickedSignOut)], [
          html.text("sign out"),
        ]),
      ])
    }
    NotFound(_uri) -> {
      html.h1([], [html.text("not found")])
    }
  }
}
