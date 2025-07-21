import client/auth
import client/network
import client/product
import client/route
import client/user
import client/view
import formal/form
import gleam/http/response
import gleam/option
import gleam/result
import lustre
import lustre/effect
import lustre/element
import lustre/element/html
import modem
import plinth/browser/document
import plinth/browser/element as browser_element
import rsvp
import shared/auth as shared_auth
import shared/context

pub fn main() -> Nil {
  let hydration = hydration_payload()

  let session = {
    hydration.session |> context.decode_session() |> option.from_result
  }

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Flags(session:))

  Nil
}

pub type Model {
  Model(route: route.Route, session: option.Option(context.Session))
}

pub type Flags {
  Flags(session: option.Option(context.Session))
}

fn init(flags: Flags) -> #(Model, effect.Effect(Msg)) {
  let route = case modem.initial_uri() {
    Ok(uri) -> route.from_uri(uri)
    Error(_) -> route.SignUp(form: form.new(), state: network.Idle)
  }

  let model = Model(route:, session: flags.session)

  let effect =
    modem.init(fn(uri) {
      uri
      |> route.from_uri
      |> UserNavigatedTo
    })

  #(model, effect)
}

pub type Msg {
  UserNavigatedTo(route: route.Route)
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
      #(Model(..model, route:), effect.none())
    }
    route.SignUp(..) as sign_up, UserSubmittedSignUpForm(form:) -> {
      case auth.decode_sign_up_form(form) {
        Ok(shared_auth.SignUpInput(..) as form) -> {
          #(
            Model(
              ..model,
              route: route.SignUp(..sign_up, state: network.Loading),
            ),
            auth.sign_up_post(form, ApiReturnedSignUp),
          )
        }
        Error(form) -> {
          #(
            Model(..model, route: route.SignUp(form:, state: network.Idle)),
            effect.none(),
          )
        }
      }
    }
    route.SignIn(..) as sign_in, UserSubmittedSignInForm(form:) -> {
      case auth.decode_sign_in_form(form) {
        Ok(shared_auth.SignInInput(..) as form) -> {
          #(
            Model(
              ..model,
              route: route.SignIn(..sign_in, state: network.Loading),
            ),
            auth.sign_in_post(form, ApiReturnedSignIn),
          )
        }
        Error(form) -> {
          #(
            Model(..model, route: route.SignIn(form:, state: network.Idle)),
            effect.none(),
          )
        }
      }
    }
    route.SignUp(..) as sign_up, ApiReturnedSignUp(Ok(res)) -> {
      let session = context.decode_session(res.body) |> option.from_result

      #(
        Model(
          route: route.SignUp(..sign_up, state: network.Success(Nil)),
          session:,
        ),
        navigate(to: route.Products),
      )
    }
    route.SignUp(..) as sign_up, ApiReturnedSignUp(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      #(
        Model(..model, route: route.SignUp(..sign_up, state: network.Err(msg:))),
        effect.none(),
      )
    }
    route.SignIn(..) as sign_in, ApiReturnedSignIn(Ok(res)) -> {
      let session = context.decode_session(res.body) |> option.from_result

      #(
        Model(
          route: route.SignIn(..sign_in, state: network.Success(Nil)),
          session:,
        ),
        navigate(to: route.Products),
      )
    }
    route.SignIn(..) as sign_in, ApiReturnedSignIn(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      #(
        Model(..model, route: route.SignIn(..sign_in, state: network.Err(msg:))),
        effect.none(),
      )
    }
    _, ApiReturnedSignOut(Ok(_)) -> {
      #(
        Model(..model, session: option.None),
        navigate(to: route.SignUp(form: form.new(), state: network.Idle)),
      )
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

fn navigate(to route: route.Route) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) { dispatch(UserNavigatedTo(route:)) })
}

pub fn view(model: Model) -> element.Element(Msg) {
  case model.route, model.session {
    route.SignIn(form:, state:), option.None -> {
      auth.sign_in_view(form:, state:, on_submit: UserSubmittedSignInForm)
    }
    route.SignUp(form:, state:), option.None -> {
      auth.sign_up_view(form:, state:, on_submit: UserSubmittedSignUpForm)
    }
    route.Account as route, option.Some(session) -> {
      element.fragment([user.account_page(session.user), view.footer(route:)])
    }
    route.CreateProduct, option.Some(..) -> {
      html.h1([], [html.text("/products/create")])
    }
    route.Products, option.Some(..) -> {
      product.page(UserClickedSignOut)
    }
    route.NotFound(_uri), _ -> {
      html.h1([], [html.text("not found")])
    }

    _ as route, _ as session -> {
      echo route
      echo session

      html.h1([], [html.text("bruhh")])
    }
  }
}

type Hydration {
  Hydration(session: String)
}

fn hydration_payload() {
  let session = {
    document.query_selector("#session")
    |> result.map(browser_element.inner_text)
    |> result.unwrap("")
  }

  Hydration(session:)
}
