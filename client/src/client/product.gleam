import client/route
import client/view
import lustre/element
import lustre/element/html
import lustre/event

pub fn page(sign_out_handler) {
  element.fragment([
    html.h1([], [html.text("/products")]),
    html.button([event.on_click(sign_out_handler)], [html.text("sign out")]),
    view.footer(route.Products),
  ])
}
