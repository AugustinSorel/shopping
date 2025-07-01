import gleam/list
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html
import product/product_model

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
      attribute.class("flex flex-col"),
    ],
    [
      html.label([attribute.class(""), attribute.for("title")], [
        html.text("title:"),
      ]),
      html.input([
        attribute.placeholder("title"),
        attribute.type_("text"),
        attribute.name("title"),
        attribute.id("title"),
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
      html.label([attribute.class(""), attribute.for("quantity")], [
        html.text("quantity:"),
      ]),
      html.input([
        attribute.placeholder("quantity"),
        attribute.type_("number"),
        attribute.name("quantity"),
        attribute.id("quantity"),
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
      html.label([attribute.class(""), attribute.for("urgent")], [
        html.text("urgent:"),
      ]),
      html.input([
        attribute.placeholder("urgent"),
        attribute.name("urgent"),
        attribute.id("urgent"),
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

pub fn by_purchased_status(
  products_purchased: List(product_model.Product),
  products_unpurchased: List(product_model.Product),
) {
  html.main([], [
    html.section([], [
      html.h2([], [html.text("à acheter")]),
      html.ol(
        [],
        list.map(products_unpurchased, fn(p) {
          html.li([], [html.text(p.title)])
        }),
      ),
    ]),
    html.section([], [
      html.h2([], [html.text("acheté")]),
      html.ol([], [
        html.li(
          [],
          list.map(products_purchased, fn(p) {
            html.li([], [html.text(p.title)])
          }),
        ),
      ]),
    ]),
    html.a([attribute.href("/products/create")], [html.text("create product")]),
  ])
}
