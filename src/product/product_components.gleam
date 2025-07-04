import components/alert
import components/button
import components/checkbox
import components/icon
import components/input
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import product/product_model
import user/user_components

pub type CreateProductInput {
  CreateProductInput(
    title: option.Option(String),
    quantity: option.Option(String),
    location: option.Option(String),
    urgent: option.Option(String),
  )
}

pub type CreateProductErrors {
  CreateProductErrors(
    root: option.Option(String),
    title: option.Option(List(String)),
    quantity: option.Option(List(String)),
    location: option.Option(List(String)),
    urgent: option.Option(List(String)),
  )
}

pub fn create_page() {
  let values = {
    CreateProductInput(
      title: option.None,
      location: option.None,
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
    option.Some(CreateProductErrors(quantity: option.Some(_), ..)) -> {
      True
    }
    option.Some(CreateProductErrors(location: option.Some(_), ..)) -> {
      True
    }
    option.Some(CreateProductErrors(urgent: option.Some(_), ..)) -> {
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
          case values {
            option.Some(CreateProductInput(title: option.Some(title), ..)) -> {
              attribute.value(title)
            }
            _ -> attribute.none()
          },
        ]),
        case errors {
          option.Some(CreateProductErrors(title: option.Some([e, ..]), ..)) -> {
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
          html.label([attribute.class("flex flex-col gap-1")], [
            html.span([attribute.class("first-letter:capitalize")], [
              html.text("location:"),
            ]),
            input.component([
              attribute.placeholder("location"),
              attribute.type_("string"),
              attribute.name("location"),
              case values {
                option.Some(CreateProductInput(
                  location: option.Some(location),
                  ..,
                )) -> {
                  attribute.value(location)
                }
                _ -> attribute.none()
              },
            ]),
            case errors {
              option.Some(CreateProductErrors(
                location: option.Some([e, ..]),
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
          alert.alert(alert.Destructive, [], [
            icon.circle_alert(),
            alert.title([], [html.text("something went wrong!")]),
            alert.description([], [html.text(e)]),
          ])
        }
        _ -> element.none()
      },
    ],
  )
}

pub fn by_purchased_status_page(children: element.Element(msg)) {
  element.fragment([
    html.header([attribute.class("max-w-app mx-auto my-10")], [
      html.h1(
        [attribute.class("text-2xl font-semibold first-letter:capitalize")],
        [html.text("shopping")],
      ),
    ]),
    children,
  ])
}

pub fn by_purchased_status(
  products_purchased: List(product_model.Product),
  products_unpurchased: List(product_model.Product),
) {
  let unpurchased_length = products_unpurchased |> list.length |> int.to_string
  let purchased_length = products_purchased |> list.length |> int.to_string

  html.main([attribute.class("mx-auto max-w-xl space-y-20")], [
    html.section([attribute.class("mx-auto max-w-xl space-y-10")], [
      html.h2([], [
        html.text("to buy "),
        html.data([attribute.value(unpurchased_length)], [
          html.text(
            ["(", unpurchased_length, ")"]
            |> string.join(with: ""),
          ),
        ]),
      ]),
      html.ol(
        [
          attribute.class(
            "divide-y divide-surface-container-highest bg-surface-container-lowest rounded-3xl overflow-hidden",
          ),
        ],
        list.map(products_unpurchased, fn(p) { item(p) }),
      ),
    ]),
    html.section([attribute.class("mx-auto max-w-xl space-y-10 mt-20")], [
      html.h2([], [
        html.text("bought "),
        html.data([attribute.value(purchased_length)], [
          html.text(["(", purchased_length, ")"] |> string.join(with: "")),
        ]),
      ]),
      html.ol(
        [
          attribute.class(
            "divide-y divide-surface-container-highest bg-surface-container-lowest rounded-3xl overflow-hidden opacity-50",
          ),
        ],
        list.map(products_purchased, fn(p) { item(p) }),
      ),
    ]),
  ])
}

pub fn by_purchase_status_fallback(msg msg: String) {
  html.main([attribute.class("mx-auto max-w-xl space-y-20")], [
    html.section([attribute.class("mx-auto max-w-xl space-y-10")], [
      html.h2([], [html.text("to buy")]),
      alert.alert(alert.Destructive, [], [
        icon.circle_alert(),
        alert.title([], [html.text("something went wrong!")]),
        alert.description([], [html.text(msg)]),
      ]),
    ]),
    html.section([attribute.class("mx-auto max-w-xl space-y-10")], [
      html.h2([], [html.text("bought")]),
      alert.alert(alert.Destructive, [], [
        icon.circle_alert(),
        alert.title([], [html.text("something went wrong!")]),
        alert.description([], [html.text(msg)]),
      ]),
    ]),
  ])
}

fn item(product: product_model.Product) {
  html.li(
    [
      attribute.class(
        "flex items-center gap-3 [&>input[type=checkbox]]:ml-auto p-4 transition-colors hover:bg-surface-container group",
      ),
    ],
    [
      user_components.avatar(product.title),
      html.div([], [
        html.header([attribute.class("flex items-center gap-2")], [
          html.label(
            [
              attribute.class(
                "cursor-pointer truncate capitalize group-has-[input:checked]:line-through font-semibold decoration-2",
              ),
              attribute.for(generate_product_id(product.id)),
            ],
            [html.text(product.title)],
          ),
          case product.urgent {
            True -> {
              html.strong(
                [
                  attribute.class(
                    "bg-error-container text-on-error-container w-max rounded-full px-2 py-1 text-xs",
                  ),
                ],
                [html.text("urgent")],
              )
            }
            False -> element.none()
          },
        ]),
        html.dl(
          [
            attribute.class(
              "text-outline flex text-sm [&>dd]:ml-1 [&>dt]:not-first-of-type:ml-2",
            ),
          ],
          [
            html.dt([], [
              html.abbr(
                [attribute.title("quantity"), attribute.class("no-underline")],
                [html.text("qty: ")],
              ),
            ]),
            html.dd([], [
              html.data([attribute.value(product.quantity |> int.to_string)], [
                html.text(product.quantity |> int.to_string),
              ]),
            ]),
            case product.location {
              option.Some(location) -> {
                element.fragment([
                  html.dt([], [html.text("location: ")]),
                  html.dd([], [html.text(location)]),
                ])
              }
              _ -> element.none()
            },
          ],
        ),
      ]),
      checkbox.component([
        attribute.id(generate_product_id(product.id)),
        attribute.checked(option.is_some(product.bought_at)),
        case product.bought_at {
          option.Some(_) -> {
            attribute.attribute(
              "hx-delete",
              string.concat(["/products/", int.to_string(product.id), "/bought"]),
            )
          }
          option.None -> {
            attribute.attribute(
              "hx-post",
              string.concat(["/products/", int.to_string(product.id), "/bought"]),
            )
          }
        },
        attribute.attribute("hx-target", "closest li"),
        attribute.attribute("hx-swap", "outerHTML"),
        attribute.attribute("hx-disabled-elt", "this"),
      ]),
    ],
  )
}

pub fn item_fallback(msg msg: String) {
  html.li([], [
    alert.alert(alert.Destructive, [], [
      icon.circle_alert(),
      alert.title([], [html.text("something went wrong!")]),
      alert.description([], [html.text(msg)]),
    ]),
  ])
}

fn generate_product_id(product_id: Int) {
  string.join(["product", int.to_string(product_id)], "-")
}
