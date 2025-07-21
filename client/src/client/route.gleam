import client/network
import formal/form
import gleam/uri

pub type Route {
  SignUp(form: form.Form, state: network.State(Nil))
  SignIn(form: form.Form, state: network.State(Nil))
  Products
  CreateProduct
  Account
  NotFound(uri: uri.Uri)
}

pub fn to_href(route: Route) {
  case route {
    Account -> "/users/account"
    CreateProduct -> "/products/create"
    NotFound(..) -> ""
    Products -> "/products"
    SignIn(..) -> "/sign-in"
    SignUp(..) -> "/sign-up"
  }
}

pub fn from_uri(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["sign-up"] -> SignUp(form: form.new(), state: network.Idle)
    ["sign-in"] -> SignIn(form: form.new(), state: network.Idle)
    [] | [""] | ["products"] -> Products
    ["products", "create"] -> CreateProduct
    ["users", "account"] -> Account
    _ -> NotFound(uri:)
  }
}
