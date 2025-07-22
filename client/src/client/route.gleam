import client/network
import formal/form
import gleam/uri
import shared/product

pub type Route {
  SignUp(form: form.Form, state: network.State(Nil))
  SignIn(form: form.Form, state: network.State(Nil))
  Products(state: network.State(product.ProductsByStatus))
  CreateProduct(form: form.Form, state: network.State(Nil))
  Account
  NotFound(uri: uri.Uri)
}

pub fn to_href(route: Route) {
  case route {
    Account -> "/users/account"
    CreateProduct(..) -> "/products/create"
    NotFound(..) -> ""
    Products(..) -> "/"
    SignIn(..) -> "/sign-in"
    SignUp(..) -> "/sign-up"
  }
}

pub fn from_uri(
  uri: uri.Uri,
  products_by_status_network: network.State(product.ProductsByStatus),
) -> Route {
  case uri.path_segments(uri.path) {
    ["sign-up"] -> SignUp(form: form.new(), state: network.Idle)
    ["sign-in"] -> SignIn(form: form.new(), state: network.Idle)
    [] | [""] -> Products(state: products_by_status_network)
    ["products", "create"] -> {
      CreateProduct(
        form: form.initial_values([#("quantity", "1")]),
        state: network.Idle,
      )
    }
    ["users", "account"] -> Account
    _ -> NotFound(uri:)
  }
}
