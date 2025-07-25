import client/auth
import client/network
import client/product
import client/route
import client/theme
import client/user
import client/view
import formal/form
import gleam/http/response
import gleam/option
import gleam/result
import gleam/string
import gleam/uri
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
import shared/product as shared_product

pub fn main() -> Nil {
  let hydration = hydration_payload()

  let session = {
    hydration.session |> context.decode_session() |> option.from_result
  }

  let products_by_status = {
    hydration.products_by_status
    |> shared_product.decode_products_by_status()
    |> option.from_result
  }

  let flags = Flags(session:, products_by_status:)

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", flags)

  Nil
}

pub type Model {
  SignUp(form: form.Form, state: network.State(Nil))
  SignIn(form: form.Form, state: network.State(Nil))
  Products(
    state: network.State(shared_product.ProductsByStatus),
    session: context.Session,
  )
  CreateProduct(
    form: form.Form,
    state: network.State(Nil),
    session: context.Session,
  )
  Account(sign_out_state: network.State(Nil), session: context.Session)
  NotFound(uri: uri.Uri)
}

pub type Flags {
  Flags(
    session: option.Option(context.Session),
    products_by_status: option.Option(shared_product.ProductsByStatus),
  )
}

fn init(flags: Flags) -> #(Model, effect.Effect(Msg)) {
  let model = case modem.initial_uri() {
    Ok(uri) -> uri_to_route(uri) |> route_to_model(flags.session)
    Error(_) -> SignUp(form: form.new(), state: network.Idle)
  }

  let effect = {
    effect.batch([
      modem.init(fn(uri) {
        uri
        |> route.from_uri()
        |> UserNavigatedTo()
      }),
      user.sync_theme(UserThemeSynchronized),
    ])
  }

  #(model, effect)
}

pub type Msg {
  UserNavigatedTo(route: route.Route)
  UserSubmittedSignUpForm(form: List(#(String, String)))
  UserSubmittedSignInForm(form: List(#(String, String)))
  UserSubmittedCreateProductForm(form: List(#(String, String)))
  UserClickedSignOut
  UserChangedTheme(theme: theme.Theme)
  UserThemeSynchronized
  UserFetchedProducts
  UserCheckedProduct(checked: Bool, id: Int)
  ApiReturnedSignUp(Result(response.Response(String), rsvp.Error))
  ApiReturnedSignIn(Result(response.Response(String), rsvp.Error))
  ApiReturnedSignOut(Result(response.Response(String), rsvp.Error))
  ApiReturnedCreateProduct(Result(response.Response(String), rsvp.Error))
  ApiReturnedProducts(Result(response.Response(String), rsvp.Error))
  ApiReturnedPatchProductBought(Result(response.Response(String), rsvp.Error))
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserNavigatedTo(route:) -> {
      let model = {
        model |> extract_session_from_model() |> route_to_model(route:)
      }

      let effect = case route {
        route.Account(..) -> user.sync_theme(UserThemeSynchronized)
        route.Products(..) -> {
          product.get_products_by_category(UserFetchedProducts)
        }
        _ -> effect.none()
      }

      #(model, effect)
    }
    UserFetchedProducts -> {
      let model = case model {
        Products(..) as page -> Products(..page, state: network.Loading)
        _ -> model
      }

      let effect = product.products_get(ApiReturnedProducts)

      #(model, effect)
    }
    UserSubmittedSignUpForm(form:) -> {
      case model {
        SignUp(..) as page -> {
          auth.decode_sign_up_form(form)
          |> result.map(fn(form) {
            let model = SignUp(..page, state: network.Loading)
            let effect = auth.sign_up_post(form, ApiReturnedSignUp)

            #(model, effect)
          })
          |> result.map_error(fn(form) {
            #(SignUp(form:, state: network.Idle), effect.none())
          })
          |> result.unwrap_both
        }
        _ -> #(model, effect.none())
      }
    }
    UserSubmittedSignInForm(form:) -> {
      case model {
        SignIn(..) as page -> {
          case auth.decode_sign_in_form(form) {
            Ok(shared_auth.SignInInput(..) as form) -> {
              #(
                SignIn(..page, state: network.Loading),
                auth.sign_in_post(form, ApiReturnedSignIn),
              )
            }
            Error(form) -> {
              #(SignIn(form:, state: network.Idle), effect.none())
            }
          }
        }
        _ -> #(model, effect.none())
      }
    }

    UserSubmittedCreateProductForm(form:) -> {
      case model {
        CreateProduct(..) as page -> {
          product.decode_create_product_form(form)
          |> result.map(fn(form) {
            let model = CreateProduct(..page, state: network.Loading)
            let effect = {
              product.create_product_post(form, ApiReturnedCreateProduct)
            }

            #(model, effect)
          })
          |> result.map_error(fn(form) {
            #(CreateProduct(..page, form:, state: network.Idle), effect.none())
          })
          |> result.unwrap_both
        }
        _ -> #(model, effect.none())
      }
    }
    UserCheckedProduct(checked:, id:) -> {
      let input = shared_product.PatchProductInput(bought: checked)

      #(model, product.patch_bought(id, input, ApiReturnedPatchProductBought))
    }

    ApiReturnedPatchProductBought(Error(_)) -> {
      #(model, product.get_products_by_category(UserFetchedProducts))
    }
    ApiReturnedPatchProductBought(Ok(_)) -> {
      #(model, product.get_products_by_category(UserFetchedProducts))
    }

    ApiReturnedSignUp(Ok(res)) -> {
      let assert Ok(session) = context.decode_session(res.body)

      let model = Products(state: network.Idle, session:)
      let effect = navigate(to: route.Products)

      #(model, effect)
    }
    ApiReturnedSignUp(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      case model {
        SignUp(..) as page -> {
          #(SignUp(..page, state: network.Err(msg:)), effect.none())
        }
        _ -> #(model, effect.none())
      }
    }
    ApiReturnedSignIn(Ok(res)) -> {
      let assert Ok(session) = context.decode_session(res.body)

      let model = Products(state: network.Idle, session: session)
      let effect = navigate(to: route.Products)

      #(model, effect)
    }
    ApiReturnedSignIn(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      case model {
        SignIn(..) as page -> {
          #(SignIn(..page, state: network.Err(msg:)), effect.none())
        }
        _ -> #(model, effect.none())
      }
    }
    ApiReturnedCreateProduct(Ok(_)) -> {
      case model {
        CreateProduct(..) as page -> {
          let model = CreateProduct(..page, state: network.Success(Nil))
          let effect = navigate(to: route.Products)

          #(model, effect)
        }
        _ -> #(model, effect.none())
      }
    }

    ApiReturnedCreateProduct(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      case model {
        CreateProduct(..) as page -> {
          #(CreateProduct(..page, state: network.Err(msg:)), effect.none())
        }
        _ -> #(model, effect.none())
      }
    }
    ApiReturnedProducts(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      let model = case model {
        Products(..) as page -> {
          Products(..page, state: network.Err(msg:))
        }
        _ -> model
      }

      #(model, effect.none())
    }
    ApiReturnedProducts(Ok(res)) -> {
      let products = shared_product.decode_products_by_status(res.body)

      case model {
        Products(..) as page -> {
          products
          |> result.map(fn(products) {
            #(Products(..page, state: network.Success(products)), effect.none())
          })
          |> result.map_error(fn(err) {
            let model = {
              Products(..page, state: network.Err(msg: string.inspect(err)))
            }

            #(model, effect.none())
          })
          |> result.unwrap_both
        }
        _ -> #(model, effect.none())
      }
    }
    UserChangedTheme(theme) -> {
      let assert Ok(root) = document.query_selector("html")

      let _ = case theme {
        theme.Dark | theme.Light -> {
          let _ = theme.save_to_local_storage(theme)

          let theme = theme.to_string(theme)

          browser_element.set_attribute(root, "data-theme", theme)
        }
        theme.Auto -> {
          let _ = theme.clear_local_storage()

          browser_element.set_attribute(root, "data-theme", "")
        }
      }

      #(model, effect.none())
    }
    UserThemeSynchronized -> {
      let theme = theme.get_from_local_storage()

      let _ =
        { "input[value='" <> theme.to_string(theme) <> "']" }
        |> document.query_selector()
        |> result.map(browser_element.set_attribute(_, "checked", "true"))

      #(model, effect.none())
    }
    ApiReturnedSignOut(Ok(_)) -> {
      #(
        SignUp(form: form.new(), state: network.Idle),
        navigate(to: route.SignUp),
      )
    }
    ApiReturnedSignOut(Error(e)) -> {
      let msg = case e {
        rsvp.HttpError(e) -> e.body
        _ -> "something went wrong"
      }

      let model = case model {
        Account(..) as page -> {
          Account(..page, sign_out_state: network.Err(msg:))
        }
        _ -> model
      }

      #(model, effect.none())
    }
    UserClickedSignOut -> {
      #(model, auth.sign_out_post(ApiReturnedSignOut))
    }
  }
}

fn navigate(to route: route.Route) -> effect.Effect(Msg) {
  effect.from(fn(dispatch) { dispatch(UserNavigatedTo(route:)) })
}

pub fn view(model: Model) -> element.Element(Msg) {
  let children = case model {
    SignIn(form:, state:) -> {
      auth.sign_in_view(form:, state:, on_submit: UserSubmittedSignInForm)
    }
    SignUp(form:, state:) -> {
      auth.sign_up_view(form:, state:, on_submit: UserSubmittedSignUpForm)
    }
    Account(sign_out_state:, session:) -> {
      user.account_view(
        [
          user.preference(
            on_theme_change: UserChangedTheme,
            sign_out_state:,
            sign_out_on_submit: UserClickedSignOut,
          ),
        ],
        session.user,
      )
    }
    CreateProduct(form:, state:, session: _) -> {
      product.create_view(
        form:,
        state:,
        on_submit: UserSubmittedCreateProductForm,
      )
    }
    Products(state:, session: _) -> {
      product.page(state:, on_check: UserCheckedProduct)
    }
    NotFound(_uri) -> {
      html.h1([], [html.text("not found")])
    }
  }

  let session = extract_session_from_model(model)

  let route = model_to_route(model)

  html.div([], [children, view.footer(route:, session:)])
}

fn extract_session_from_model(model: Model) {
  case model {
    Account(session:, ..) -> option.Some(session)
    CreateProduct(session:, ..) -> option.Some(session)
    NotFound(..) -> option.None
    Products(session:, ..) -> option.Some(session)
    SignIn(..) -> option.None
    SignUp(..) -> option.None
  }
}

fn model_to_route(model: Model) {
  case model {
    Account(..) -> route.Account
    CreateProduct(..) -> route.CreateProduct
    NotFound(uri:) -> route.NotFound(uri:)
    Products(..) -> route.Products
    SignIn(..) -> route.SignIn
    SignUp(..) -> route.SignUp
  }
}

fn uri_to_route(uri: uri.Uri) {
  case uri.path_segments(uri.path) {
    ["sign-up"] -> route.SignUp
    ["sign-in"] -> route.SignIn
    [] | [""] -> route.Products
    ["products", "create"] -> route.CreateProduct
    ["users", "account"] -> route.Account
    _ -> route.NotFound(uri:)
  }
}

fn route_to_model(
  route route: route.Route,
  session session: option.Option(context.Session),
) {
  case route {
    route.Account -> {
      let assert option.Some(session) = session
      Account(sign_out_state: network.Idle, session:)
    }
    route.CreateProduct -> {
      let assert option.Some(session) = session
      CreateProduct(form: form.new(), state: network.Idle, session:)
    }
    route.NotFound(uri:) -> NotFound(uri:)
    route.Products -> {
      let assert option.Some(session) = session
      Products(state: network.Loading, session:)
    }
    route.SignIn -> SignIn(form: form.new(), state: network.Idle)
    route.SignUp -> SignUp(form: form.new(), state: network.Idle)
  }
}

type Hydration {
  Hydration(session: String, products_by_status: String)
}

fn hydration_payload() {
  let session = {
    document.query_selector(string.concat(["#", context.session_hydration_key]))
    |> result.map(browser_element.inner_text)
    |> result.unwrap("")
  }

  let products_by_status = {
    document.query_selector(
      string.concat(["#", shared_product.products_by_status_hydration_key]),
    )
    |> result.map(browser_element.inner_text)
    |> result.unwrap("")
  }

  Hydration(session:, products_by_status:)
}
//BUG: navigation not changing the url
//TODO: data validation
