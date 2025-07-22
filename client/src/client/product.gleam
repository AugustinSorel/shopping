import client/icon
import client/network
import client/route
import client/view
import formal/form
import gleam/json
import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import rsvp
import shared/product

pub fn page(sign_out_handler) {
  element.fragment([
    html.h1([], [html.text("/products")]),
    html.button([event.on_click(sign_out_handler)], [html.text("sign out")]),
    view.footer(route.Products),
  ])
}

pub fn create_view(
  form form: form.Form,
  state state: network.State(a),
  on_submit on_submit,
) {
  html.div([], [
    html.main([attribute.class("max-w-app mx-auto py-10 space-y-10")], [
      html.h1(
        [attribute.class("text-2xl font-semibold first-letter:capitalize")],
        [html.text("create product")],
      ),
      html.form(
        [
          attribute.attribute("hx-post", "/products"),
          attribute.attribute("hx-target", "this"),
          attribute.attribute("hx-swap", "outerHTML"),
          attribute.attribute("hx-disabled-elt", "find button[type='submit']"),
          attribute.class("flex flex-col gap-10"),
          event.on_submit(on_submit),
        ],
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
    ]),
    view.footer(route.Products),
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
  |> form.field("location", fn(input) {
    case input {
      "" -> Ok(option.None)
      location -> Ok(option.Some(location))
    }
  })
  |> form.field("urgent", form.bool)
  |> form.finish
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
