import gleam/uri

pub type Route {
  SignUp
  SignIn
  Products
  CreateProduct
  Account
  NotFound(uri: uri.Uri)
}

pub fn to_href(route: Route) {
  case route {
    Account(..) -> "/users/account"
    CreateProduct(..) -> "/products/create"
    NotFound(..) -> ""
    Products(..) -> "/"
    SignIn -> "/sign-in"
    SignUp -> "/sign-up"
  }
}

pub fn from_uri(uri: uri.Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["sign-up"] -> SignUp
    ["sign-in"] -> SignIn
    [] | [""] -> Products
    ["products", "create"] -> CreateProduct
    ["users", "account"] -> Account
    _ -> NotFound(uri:)
  }
}
