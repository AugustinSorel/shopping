import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html

pub type CreateProductInput {
  CreateProductInput(
    name: option.Option(String),
    quantity: option.Option(String),
    urgent: option.Option(String),
  )
}

pub type CreateProductErrors {
  CreateProductErrors(
    root: option.Option(List(String)),
    name: option.Option(List(String)),
    quantity: option.Option(List(String)),
    urgent: option.Option(List(String)),
  )
}

pub fn create_form(
  values: option.Option(CreateProductInput),
  errors: option.Option(CreateProductErrors),
) {
  html.form(
    [
      attribute.attribute("hx-post", "/products"),
      attribute.attribute("hx-target", "this"),
    ],
    [
      html.input([
        attribute.placeholder("name"),
        attribute.type_("text"),
        attribute.name("name"),
        case values {
          option.Some(CreateProductInput(name: option.Some(name), ..)) -> {
            attribute.value(name)
          }
          _ -> attribute.none()
        },
      ]),
      case errors {
        option.Some(CreateProductErrors(name: option.Some([e, ..]), ..)) -> {
          html.p([], [html.text(e)])
        }
        _ -> element.none()
      },
      html.input([
        attribute.placeholder("quantity"),
        attribute.type_("number"),
        attribute.name("quantity"),
        case values {
          option.Some(CreateProductInput(quantity: option.Some(quantity), ..)) -> {
            attribute.value(quantity)
          }
          _ -> attribute.none()
        },
      ]),
      case errors {
        option.Some(CreateProductErrors(quantity: option.Some([e, ..]), ..)) -> {
          html.p([], [html.text(e)])
        }
        _ -> element.none()
      },
      html.input([
        attribute.placeholder("urgent"),
        attribute.name("urgent"),
        attribute.type_("checkbox"),
        case values {
          option.Some(CreateProductInput(urgent: option.Some("on"), ..)) -> {
            attribute.checked(True)
          }
          _ -> attribute.none()
        },
      ]),
      case errors {
        option.Some(CreateProductErrors(urgent: option.Some([e, ..]), ..)) -> {
          html.p([], [html.text(e)])
        }
        _ -> element.none()
      },
      html.button([], [html.text("submit")]),
      case errors {
        option.Some(CreateProductErrors(root: option.Some([e, ..]), ..)) -> {
          html.p([], [html.text(e)])
        }
        _ -> element.none()
      },
    ],
  )
}

pub fn by_purchased_status() {
  html.main([], [
    html.section([], [
      html.h2([], [html.text("à acheter")]),
      html.ol([], [html.li([], [html.text("...")])]),
    ]),
    html.section([], [
      html.h2([], [html.text("acheté")]),
      html.ol([], [html.li([], [html.text("...")])]),
    ]),
    html.a([attribute.href("/products/create")], [html.text("create product")]),
  ])
}
