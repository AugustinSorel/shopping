import client/icon
import client/network
import client/view
import formal/form
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import shared/product

pub fn get_products_by_category(repsonse) {
  effect.from(fn(dispatch) { dispatch(repsonse) })
}

pub fn products_get(handle_response) {
  rsvp.get("/products", rsvp.expect_ok_response(handle_response))
}

pub fn patch_bought(
  product_id: Int,
  input: product.PatchProductInput,
  handle_response,
) {
  let body = {
    json.object([#("bought", json.bool(input.bought))]) |> json.to_string
  }

  let request =
    request.new()
    |> request.set_method(http.Patch)
    |> request.set_host("localhost")
    |> request.set_port(8080)
    |> request.set_body(body)
    |> request.set_scheme(http.Http)
    |> request.set_header("content-type", "application/json")
    |> request.set_path(
      "/products/" <> product_id |> int.to_string <> "/bought",
    )

  let handler = rsvp.expect_ok_response(handle_response)

  rsvp.send(request, handler)
}

pub fn page(
  state state: network.State(product.ProductsByStatus),
  on_check on_check,
) {
  element.fragment([
    html.header([attribute.class("max-w-app mx-auto my-10")], [
      html.h1(
        [attribute.class("text-2xl font-semibold first-letter:capitalize")],
        [html.text("shopping")],
      ),
    ]),
    html.main([attribute.class("mx-auto max-w-xl space-y-20")], [
      case state {
        network.Err(msg:) ->
          view.alert(view.Destructive, [], [
            icon.circle_alert([]),
            view.alert_title([], [html.text("something went wrong")]),
            view.alert_description([], [html.text(msg)]),
          ])
        network.Idle -> element.none()
        network.Loading -> view.spinner([], icon.Small)
        network.Success(data:) -> by_purchased_status(data, on_check:)
      },
    ]),
  ])
}

pub fn by_purchased_status(
  products: product.ProductsByStatus,
  on_check on_check,
) {
  let unpurchased_length = products.unpurchased |> list.length |> int.to_string
  let purchased_length = products.purchased |> list.length |> int.to_string

  element.fragment([
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
        list.map(products.unpurchased, item(_, on_check:)),
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
        list.map(products.purchased, item(_, on_check:)),
      ),
    ]),
  ])
}

fn item(product: product.Product, on_check on_check) {
  html.li(
    [
      attribute.class(
        "flex items-center gap-3 [&>input[type=checkbox]]:ml-auto p-4 transition-colors hover:bg-surface-container group",
      ),
    ],
    [
      view.avatar(product.title),
      html.div([], [
        html.header([attribute.class("flex items-center gap-2")], [
          html.label(
            [
              attribute.class(
                "cursor-pointer truncate capitalize group-has-[input:checked]:line-through font-semibold decoration-2",
              ),
              attribute.for(product.id |> int.to_string),
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
      view.checkbox([
        attribute.checked(product.bought_at |> option.is_some),
        event.on_check(fn(e) { on_check(e, product.id) }),
        attribute.id(product.id |> int.to_string),
        attribute.checked(option.is_some(product.bought_at)),
      ]),
    ],
  )
}

pub fn create_view(
  form form: form.Form,
  state state: network.State(a),
  on_submit on_submit,
) {
  html.main([attribute.class("max-w-app mx-auto py-10 space-y-10")], [
    html.h1(
      [attribute.class("text-2xl font-semibold first-letter:capitalize")],
      [html.text("create product")],
    ),
    html.form(
      [attribute.class("flex flex-col gap-10"), event.on_submit(on_submit)],
      [
        html.label([attribute.class("flex flex-col gap-1")], [
          html.span([attribute.class("first-letter:capitalize")], [
            html.text("title:"),
          ]),
          view.input([
            attribute.placeholder("title"),
            attribute.type_("text"),
            attribute.name("title"),
          ]),
          case form.field_state(form, "title") {
            Ok(_) -> element.none()
            Error(e) -> {
              html.p(
                [attribute.class("text-error text-sm first-letter:capitalize")],
                [html.text(e)],
              )
            }
          },
        ]),
        html.details([attribute.class("space-y-5")], [
          html.summary([attribute.class("text-outline cursor-pointer")], [
            html.text("advanced"),
          ]),
          html.label([attribute.class("flex flex-col gap-1")], [
            html.span([attribute.class("first-letter:capitalize")], [
              html.text("quantity:"),
            ]),
            view.input([
              attribute.placeholder("quantity"),
              attribute.type_("number"),
              attribute.name("quantity"),
              attribute.value(form.value(form, "quantity")),
            ]),
            case form.field_state(form, "quantity") {
              Ok(_) -> element.none()
              Error(e) -> {
                html.p(
                  [
                    attribute.class(
                      "text-error text-sm first-letter:capitalize",
                    ),
                  ],
                  [html.text(e)],
                )
              }
            },
          ]),
          html.label([attribute.class("flex flex-col gap-1")], [
            html.span([attribute.class("first-letter:capitalize")], [
              html.text("location:"),
            ]),
            view.input([
              attribute.placeholder("location"),
              attribute.type_("string"),
              attribute.name("location"),
            ]),
            case form.field_state(form, "location") {
              Ok(_) -> element.none()
              Error(e) -> {
                html.p(
                  [
                    attribute.class(
                      "text-error text-sm first-letter:capitalize",
                    ),
                  ],
                  [html.text(e)],
                )
              }
            },
          ]),
          html.label([attribute.class("grid grid-cols-[1fr_auto] gap-1")], [
            html.span([attribute.class("first-letter:capitalize")], [
              html.text("urgent:"),
            ]),
            view.checkbox([
              attribute.placeholder("urgent"),
              attribute.name("urgent"),
              attribute.id("urgent"),
            ]),
            case form.field_state(form, "urgent") {
              Ok(_) -> element.none()
              Error(e) -> {
                html.p(
                  [
                    attribute.class(
                      "text-error text-sm first-letter:capitalize",
                    ),
                  ],
                  [html.text(e)],
                )
              }
            },
          ]),
        ]),
        view.button(
          view.Default,
          view.Medium,
          [
            attribute.type_("submit"),
            attribute.disabled(case state {
              network.Loading -> True
              _ -> False
            }),
          ],
          [
            html.text("create"),
            case state {
              network.Loading -> view.spinner([], icon.Small)
              _ -> element.none()
            },
          ],
        ),
        case state {
          network.Err(msg:) -> {
            view.alert(view.Destructive, [], [
              icon.circle_alert([]),
              view.alert_title([], [html.text("something went wrong")]),
              view.alert_description([], [html.text(msg)]),
            ])
          }
          _ -> element.none()
        },
      ],
    ),
  ])
}

pub fn decode_create_product_form(values: List(#(String, String))) {
  form.decoding({
    use title <- form.parameter
    use quantity <- form.parameter
    use location <- form.parameter
    use urgent <- form.parameter

    product.CreateProductInput(title:, quantity:, location:, urgent:)
  })
  |> form.with_values(values)
  |> form.field(
    "title",
    form.string
      |> form.and(
        form.must_not_be_empty
        |> form.message("title cannot be blank"),
      )
      |> form.and(
        form.must_be_string_longer_than(3)
        |> form.message("title must be at least 3 characters"),
      )
      |> form.and(
        form.must_be_string_shorter_than(255)
        |> form.message("title must be at most 255 characters"),
      ),
  )
  |> form.field(
    "quantity",
    form.int
      |> form.and(
        form.must_be_greater_int_than(0)
        |> form.message("quantity must be above 0"),
      )
      |> form.and(
        form.must_be_lesser_int_than(100)
        |> form.message("quantity must be under 100"),
      ),
  )
  |> form.field(
    "location",
    fn(input) {
      case input {
        "" -> Ok(option.None)
        location -> Ok(option.Some(location))
      }
    }
      |> form.and(fn(input) {
        case input {
          option.None -> Ok(option.None)
          option.Some(input) -> {
            form.must_be_string_longer_than(10)(input)
            |> result.map(fn(d) { option.Some(d) })
          }
        }
      })
      |> form.and(if_provided(
        form.must_be_string_longer_than(3)
        |> form.message("location must be at least 3 characters"),
      ))
      |> form.and(if_provided(
        form.must_be_string_shorter_than(255)
        |> form.message("location must be at most 255 characters"),
      )),
  )
  |> form.field("urgent", form.bool)
  |> form.finish
}

fn if_provided(cb) {
  fn(input: option.Option(a)) {
    case input {
      option.None -> Ok(option.None)
      option.Some(input) -> {
        cb(input)
        |> result.map(option.Some)
      }
    }
  }
}

pub fn create_product_post(form: product.CreateProductInput, handle_response) {
  let body =
    json.object([
      #("title", json.string(form.title)),
      #("quantity", json.int(form.quantity)),
      #("location", case form.location {
        option.None -> json.null()
        option.Some(location) -> json.string(location)
      }),
      #("urgent", json.bool(form.urgent)),
    ])

  rsvp.post("/products", body, rsvp.expect_ok_response(handle_response))
}
