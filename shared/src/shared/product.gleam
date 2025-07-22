import gleam/dynamic/decode
import gleam/json
import gleam/option

pub const products_by_status_hydration_key = "products_by_status"

pub type CreateProductInput {
  CreateProductInput(
    title: String,
    quantity: Int,
    location: option.Option(String),
    urgent: Bool,
  )
}

pub type Product {
  Product(
    id: Int,
    user_id: Int,
    title: String,
    quantity: Int,
    urgent: Bool,
    location: option.Option(String),
    bought_at: option.Option(String),
    created_at: String,
    updated_at: String,
  )
}

pub type ProductsByStatus {
  ProductsByStatus(purchased: List(Product), unpurchased: List(Product))
}

pub fn encode_products_by_status(products: ProductsByStatus) {
  json.object([
    #("purchased", json.array(products.purchased, product_encoder)),
    #("unpurchased", json.array(products.unpurchased, product_encoder)),
  ])
  |> json.to_string
}

pub fn product_encoder(product: Product) {
  json.object([
    #("id", json.int(product.id)),
    #("user_id", json.int(product.user_id)),
    #("title", json.string(product.title)),
    #("quantity", json.int(product.quantity)),
    #("urgent", json.bool(product.urgent)),
    #("location", json.nullable(product.location, json.string)),
    #("bought_at", json.nullable(product.bought_at, json.string)),
    #("updated_at", json.string(product.updated_at)),
    #("created_at", json.string(product.created_at)),
  ])
}

pub fn product_decoder() {
  use id <- decode.field("id", decode.int)
  use user_id <- decode.field("user_id", decode.int)
  use title <- decode.field("title", decode.string)
  use quantity <- decode.field("quantity", decode.int)
  use urgent <- decode.field("urgent", decode.bool)
  use location <- decode.field("location", decode.optional(decode.string))
  use bought_at <- decode.field("bought_at", decode.optional(decode.string))
  use updated_at <- decode.field("updated_at", decode.string)
  use created_at <- decode.field("created_at", decode.string)

  decode.success(Product(
    id:,
    user_id:,
    title:,
    quantity:,
    urgent:,
    location:,
    bought_at:,
    updated_at:,
    created_at:,
  ))
}

pub fn decode_products_by_status(products: String) {
  json.parse(products, {
    use purchased <- decode.field("purchased", decode.list(product_decoder()))
    use unpurchased <- decode.field(
      "unpurchased",
      decode.list(product_decoder()),
    )

    decode.success(ProductsByStatus(purchased:, unpurchased:))
  })
}
