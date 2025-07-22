import gleam/dynamic
import gleam/dynamic/decode
import gleam/option
import gleam/result
import gleam/time/timestamp
import pog
import server/error
import shared/product

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

pub fn decode_create_product(json: dynamic.Dynamic) {
  echo json
  let res = {
    decode.run(json, create_product_decoder())
    |> result.map_error(fn(e) {
      error.ProductValidation(errors: error.decode_to_validation(e))
    })
  }

  use sign_up <- result.try(res)

  Ok(sign_up)
}

fn create_product_decoder() -> decode.Decoder(product.CreateProductInput) {
  use title <- decode.field("title", decode.string)
  use quantity <- decode.field("quantity", decode.int)
  use location <- decode.field("location", decode.optional(decode.string))
  use urgent <- decode.field("urgent", decode.bool)

  decode.success(product.CreateProductInput(
    title:,
    quantity:,
    location:,
    urgent:,
  ))
}

pub fn insert(
  input: product.CreateProductInput,
  user_id: Int,
  db: pog.Connection,
) {
  let query = {
    "insert into products (title,quantity,location,urgent,user_id) values ($1,$2,$3,$4,$5) returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(input.title))
    |> pog.parameter(pog.int(input.quantity))
    |> pog.parameter(pog.nullable(fn(e) { pog.text(e) }, input.location))
    |> pog.parameter(pog.bool(input.urgent))
    |> pog.parameter(pog.int(user_id))
    |> pog.returning(product_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, products)) -> Ok(products)
    Error(_) -> Error(error.Internal(msg: "creating products failed"))
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
