import components/button
import components/checkbox
import components/input
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
    root: option.Option(String),
    name: option.Option(List(String)),
    quantity: option.Option(List(String)),
    urgent: option.Option(List(String)),
  )
}

pub fn create_page() {
  let values = {
    CreateProductInput(
      name: option.None,
      quantity: option.Some("1"),
      urgent: option.None,
    )
  }

  html.main([attribute.class("max-w-app mx-auto py-10 space-y-10")], [
    html.h1(
      [attribute.class("text-2xl font-semibold first-letter:capitalize")],
      [html.text("create product")],
    ),
    create_form(option.Some(values), option.None),
  ])
}

pub fn create_form(
  values: option.Option(CreateProductInput),
  errors: option.Option(CreateProductErrors),
) {
  let details_open = case errors {
    option.Some(CreateProductErrors(_root, _title, option.Some(_qty), _urgent)) -> {
      True
    }
    option.Some(CreateProductErrors(_root, _title, _qty, option.Some(_urgent))) -> {
      True
    }
    _ -> False
  }

  html.form(
    [
      attribute.attribute("hx-post", "/products"),
      attribute.attribute("hx-target", "this"),
      attribute.attribute("hx-swap", "outerHTML"),
      attribute.class("flex flex-col gap-10"),
    ],
    [
      html.label([attribute.class("flex flex-col gap-1")], [
        html.span([attribute.class("first-letter:capitalize")], [
          html.text("title:"),
        ]),
        input.component([
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
            html.p(
              [attribute.class("text-error text-sm first-letter:capitalize")],
              [html.text(e)],
            )
          }
          _ -> element.none()
        },
      ]),
      html.details(
        [
          attribute.class("space-y-5"),
          case details_open {
            True -> attribute.attribute("open", "")
            False -> attribute.none()
          },
        ],
        [
          html.summary([attribute.class("text-outline cursor-pointer")], [
            html.text("advanced"),
          ]),
          html.label([attribute.class("flex flex-col gap-1")], [
            html.span([attribute.class("first-letter:capitalize")], [
              html.text("quantity:"),
            ]),
            input.component([
              attribute.placeholder("quantity"),
              attribute.type_("number"),
              attribute.name("quantity"),
              attribute.id("quantity"),
              case values {
                option.Some(CreateProductInput(
                  quantity: option.Some(quantity),
                  ..,
                )) -> {
                  attribute.value(quantity)
                }
                _ -> attribute.none()
              },
            ]),
            case errors {
              option.Some(CreateProductErrors(
                quantity: option.Some([e, ..]),
                ..,
              )) -> {
                html.p(
                  [
                    attribute.class(
                      "text-error text-sm first-letter:capitalize",
                    ),
                  ],
                  [html.text(e)],
                )
              }
              _ -> element.none()
            },
          ]),
          html.label([attribute.class("grid grid-cols-[1fr_auto] gap-1")], [
            html.span([attribute.class("first-letter:capitalize")], [
              html.text("urgent:"),
            ]),
            checkbox.component([
              attribute.placeholder("urgent"),
              attribute.name("urgent"),
              attribute.id("urgent"),
              case values {
                option.Some(CreateProductInput(urgent: option.Some("on"), ..)) -> {
                  attribute.checked(True)
                }
                _ -> attribute.none()
              },
            ]),
            case errors {
              option.Some(CreateProductErrors(urgent: option.Some([e, ..]), ..)) -> {
                html.p(
                  [
                    attribute.class(
                      "text-error text-sm first-letter:capitalize",
                    ),
                  ],
                  [html.text(e)],
                )
              }
              _ -> element.none()
            },
          ]),
        ],
      ),
      button.component(button.Default, button.Medium, [], [html.text("create")]),
      case errors {
        option.Some(CreateProductErrors(root: option.Some(e), ..)) -> {
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
