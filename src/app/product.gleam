import app/error
import app/icon
import app/validator
import app/view
import app/web
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/time/timestamp
import lustre/attribute
import lustre/element
import lustre/element/html
import pog
import valid

pub type Product {
  Product(
    id: Int,
    user_id: Int,
    title: String,
    quantity: Int,
    urgent: Bool,
    location: option.Option(String),
    bought_at: option.Option(timestamp.Timestamp),
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
  )
}

fn get_all(db: pog.Connection) {
  let query = {
    "select * from products as p order by p.urgent desc, p.updated_at desc"
  }

  let response =
    pog.query(query)
    |> pog.returning(product_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, products)) -> Ok(products)
    Error(_) -> Error(error.Internal(msg: "fetching all products failed"))
  }
}

pub fn create(
  db: pog.Connection,
  title: String,
  quantity: Int,
  location: option.Option(String),
  urgent: Bool,
  user_id: Int,
) {
  let query = {
    "insert into products (title,quantity,location,urgent,user_id) values ($1,$2,$3,$4,$5) returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(title))
    |> pog.parameter(pog.int(quantity))
    |> pog.parameter(pog.nullable(fn(e) { pog.text(e) }, location))
    |> pog.parameter(pog.bool(urgent))
    |> pog.parameter(pog.int(user_id))
    |> pog.returning(product_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, products)) -> Ok(products)
    Error(_) -> Error(error.Internal(msg: "creating products failed"))
  }
}

pub fn create_bought_at(db: pog.Connection, product_id: Int) {
  let query = {
    "update products set bought_at = now() where id = $1 returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.int(product_id))
    |> pog.returning(product_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, [product, ..])) -> Ok(product)
    Ok(pog.Returned(_rows, [])) -> Error(error.ProductNotFound)
    Error(_) -> {
      Error(error.Internal(msg: "creating bought at to product failed"))
    }
  }
}

pub fn delete_bought_at(db: pog.Connection, product_id: Int) {
  let query = {
    "update products set bought_at = null where id = $1 returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.int(product_id))
    |> pog.returning(product_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, [product, ..])) -> Ok(product)
    Ok(pog.Returned(_rows, [])) -> Error(error.ProductNotFound)
    Error(_) -> {
      Error(error.Internal(msg: "deleting bought at to product failed"))
    }
  }
}

fn product_row_decoder() {
  use id <- decode.field(0, decode.int)
  use user_id <- decode.field(1, decode.int)
  use title <- decode.field(2, decode.string)
  use quantity <- decode.field(3, decode.int)
  use location <- decode.field(4, decode.optional(decode.string))
  use urgent <- decode.field(5, decode.bool)
  use bought_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
  use created_at <- decode.field(7, pog.timestamp_decoder())
  use updated_at <- decode.field(8, pog.timestamp_decoder())

  decode.success(Product(
    id:,
    user_id:,
    title:,
    quantity:,
    location:,
    urgent:,
    bought_at:,
    created_at:,
    updated_at:,
  ))
}

pub type ProductStats {
  ProductStats(user_count: Int, total_count: Int)
}

pub fn get_stats(user_id: Int, db: pog.Connection) {
  let query = {
    "select
  		 count(*) filter (where user_id = $1),
  		 count(*)
		from products"
  }

  let row_decoder = {
    use user_count <- decode.field(0, decode.int)
    use total_count <- decode.field(1, decode.int)

    decode.success(ProductStats(user_count:, total_count:))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.int(user_id))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, [stats, ..])) -> Ok(stats)
    Ok(pog.Returned(_rows, [])) -> Error(error.ProductNotFound)
    Error(_) -> Error(error.Internal(msg: "fetching products stats failed"))
  }
}

pub type ProductsByStatus {
  ProductsByStatus(purchased: List(Product), unpurchased: List(Product))
}

pub fn get_by_purchase_status(ctx: web.Ctx) {
  use products <- result.try(get_all(ctx.db))

  let products_by_purchased_status = {
    list.partition(products, fn(p) { option.is_some(p.bought_at) })
  }

  let #(purchased, unpurchased) = products_by_purchased_status

  Ok(ProductsByStatus(purchased:, unpurchased:))
}

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
      attribute.attribute("hx-disabled-elt", "find button[type='submit']"),
      attribute.class("flex flex-col gap-10"),
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
            view.input([
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
            view.input([
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
            view.checkbox([
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
      view.button(view.Default, view.Medium, [attribute.type_("submit")], [
        html.text("create"),
        view.spinner([], icon.Small),
      ]),
      case errors {
        option.Some(CreateProductErrors(root: option.Some(e), ..)) -> {
          view.alert(view.Destructive, [], [
            icon.circle_alert([]),
            view.alert_title([], [html.text("something went wrong!")]),
            view.alert_description([], [html.text(e)]),
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
  products_purchased: List(Product),
  products_unpurchased: List(Product),
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
      view.alert(view.Destructive, [], [
        icon.circle_alert([]),
        view.alert_title([], [html.text("something went wrong!")]),
        view.alert_description([], [html.text(msg)]),
      ]),
    ]),
    html.section([attribute.class("mx-auto max-w-xl space-y-10")], [
      html.h2([], [html.text("bought")]),
      view.alert(view.Destructive, [], [
        icon.circle_alert([]),
        view.alert_title([], [html.text("something went wrong!")]),
        view.alert_description([], [html.text(msg)]),
      ]),
    ]),
  ])
}

fn item(product: Product) {
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
      view.checkbox([
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
    view.alert(view.Destructive, [], [
      icon.circle_alert([]),
      view.alert_title([], [html.text("something went wrong!")]),
      view.alert_description([], [html.text(msg)]),
    ]),
  ])
}

fn generate_product_id(product_id: Int) {
  string.join(["product", int.to_string(product_id)], "-")
}

pub fn stats(stats: ProductStats) {
  html.section(
    [attribute.class("bg-surface-container-lowest space-y-3 rounded-3xl p-6")],
    [
      html.h2(
        [attribute.class("text-lg font-semibold first-letter:capitalize")],
        [html.text("info:")],
      ),
      html.dl(
        [
          attribute.class(
            "grid grid-cols-[1fr_auto] [&>dt]:first-letter:capitalize",
          ),
        ],
        [
          html.dt([], [html.text("your count")]),
          html.dd([], [
            html.data(
              [attribute.data("your count", stats.user_count |> int.to_string)],
              [html.text(stats.user_count |> int.to_string)],
            ),
          ]),
          html.dt([], [html.text("total products")]),
          html.dd([], [
            html.data(
              [
                attribute.data(
                  "total count",
                  stats.total_count |> int.to_string,
                ),
              ],
              [html.text(stats.total_count |> int.to_string)],
            ),
          ]),
        ],
      ),
    ],
  )
}

pub fn stats_fallback(msg: String) {
  view.alert(view.Destructive, [], [
    icon.circle_alert([]),
    view.alert_title([], [html.text("Could not load stats")]),
    view.alert_description([], [html.text(msg)]),
  ])
}

pub type Fields {
  Title
  Quantity
  Location
  Urgent
  Id
}

fn validate_title() {
  let error = fn(msg) { #(Title, msg) }

  validator.trim
  |> valid.then(valid.string_is_not_empty(error("title  is required")))
  |> valid.then(valid.string_min_length(
    3,
    error("title  must be at least 3 characters"),
  ))
  |> valid.then(valid.string_max_length(
    255,
    error("title must be at most 255 characters"),
  ))
  |> validator.string_required(error("title is required"))
}

fn validate_quantity() {
  let error = fn(msg) { #(Quantity, msg) }

  validator.trim
  |> validator.int_coerce(
    valid.string_is_int(error("quantity must of type int")),
  )
  |> valid.then(valid.int_min(1, error("quantity must be at least 1")))
  |> valid.then(valid.int_max(255, error("quantity must be at most 255")))
  |> validator.default(1)
}

fn validate_urgent() {
  let error = fn(msg) { #(Urgent, msg) }

  validator.trim
  |> validator.bool_coerce(
    validator.string_is_bool(error("urgent must be of type bool")),
  )
  |> validator.default(False)
}

fn validate_location() {
  let error = fn(msg) { #(Location, msg) }

  validator.empty_str_as_none()
  |> valid.then(
    validator.trim
    |> valid.then(valid.string_is_not_empty(error("location is required")))
    |> valid.then(valid.string_min_length(
      3,
      error("location must be at least 3 characters"),
    ))
    |> valid.then(valid.string_max_length(
      255,
      error("location must be at most 255 characters"),
    ))
    |> valid.optional,
  )
}

fn validate_id() {
  let error = fn(msg) { #(Id, msg) }

  validator.trim
  |> validator.int_coerce(valid.string_is_int(error("id must of type int")))
  |> valid.then(valid.int_min(0, error("id must be at least 1")))
}

pub type CreateOutput {
  CreateOutput(
    title: String,
    quantity: Int,
    location: option.Option(String),
    urgent: Bool,
  )
}

pub fn validate_create(input: CreateProductInput) {
  input
  |> valid.validate(fn(input) {
    use title <- valid.check(input.title, validate_title())
    use quantity <- valid.check(input.quantity, validate_quantity())
    use location <- valid.check(input.location, validate_location())
    use urgent <- valid.check(input.urgent, validate_urgent())

    valid.ok(CreateOutput(title:, quantity:, location:, urgent:))
  })
  |> result.map_error(fn(errors) {
    error.ProductValidation(
      id: option.None,
      title: error.messages_for(Title, errors),
      quantity: error.messages_for(Quantity, errors),
      location: error.messages_for(Location, errors),
      urgent: error.messages_for(Urgent, errors),
    )
  })
}

pub fn validate_id_str(input: String) {
  input
  |> valid.validate(fn(input) {
    use id <- valid.check(input, validate_id())

    valid.ok(id)
  })
  |> result.map_error(fn(errors) {
    error.ProductValidation(
      id: error.messages_for(Id, errors),
      title: option.None,
      quantity: option.None,
      location: option.None,
      urgent: option.None,
    )
  })
}
