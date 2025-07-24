import gleam/bool
import gleam/dynamic
import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import pog
import server/error
import shared/product

pub fn decode_create_product(json: dynamic.Dynamic) {
  let res = {
    decode.run(json, create_product_decoder())
    |> result.map_error(fn(e) {
      error.ProductValidation(errors: error.decode_to_validation(e))
    })
  }

  use input <- result.try(res)

  Ok(input)
}

pub fn decode_patch_product(json: dynamic.Dynamic) {
  let res = {
    decode.run(json, patch_product_decoder())
    |> result.map_error(fn(e) {
      error.ProductValidation(errors: error.decode_to_validation(e))
    })
  }

  use input <- result.try(res)

  Ok(input)
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

fn patch_product_decoder() -> decode.Decoder(product.PatchProductInput) {
  use bought <- decode.field("bought", decode.bool)

  decode.success(product.PatchProductInput(bought:))
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

pub fn get_all(db: pog.Connection) {
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

pub fn patch_bought(bought: Bool, product_id: Int, db: pog.Connection) {
  let bought_at = {
    bool.guard(when: bought, return: "now()", otherwise: fn() { "null" })
  }

  let query = {
    "update products set bought_at = "
    <> bought_at
    <> " where id = $1 returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.int(product_id))
    |> pog.returning(product_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, [product, ..])) -> Ok(product)
    Ok(pog.Returned(_rows, [])) -> Error(error.ProductNotFound)
    Error(_) -> Error(error.Internal(msg: "fetching all products failed"))
  }
}

pub fn get_by_purchase_status(db: pog.Connection) {
  use products <- result.try(get_all(db))

  let products_by_purchased_status = {
    list.partition(products, fn(p) { option.is_some(p.bought_at) })
  }

  let #(purchased, unpurchased) = products_by_purchased_status

  Ok(product.ProductsByStatus(purchased:, unpurchased:))
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

  decode.success(product.Product(
    id:,
    user_id:,
    title:,
    quantity:,
    location:,
    urgent:,
    bought_at: option.map(bought_at, string.inspect),
    created_at: string.inspect(created_at),
    updated_at: string.inspect(updated_at),
  ))
}
