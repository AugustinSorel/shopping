import app/error
import gleam/dynamic/decode
import gleam/option
import pog
import product/product_model

pub fn get_all(db: pog.Connection) {
  let query = {
    "select * from products as p order by p.urgent desc, p.updated_at desc"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use title <- decode.field(1, decode.string)
    use quantity <- decode.field(2, decode.int)
    use location <- decode.field(3, decode.optional(decode.string))
    use urgent <- decode.field(4, decode.bool)
    use bought_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())

    decode.success(product_model.Product(
      id:,
      title:,
      quantity:,
      urgent:,
      location:,
      bought_at:,
      created_at:,
      updated_at:,
    ))
  }

  let response =
    pog.query(query)
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, products)) -> {
      Ok(products)
    }
    Error(_e) -> {
      Error(error.Internal(msg: "fetching all products failed"))
    }
  }
}

pub fn create(
  db: pog.Connection,
  title: String,
  quantity: Int,
  location: option.Option(String),
  urgent: Bool,
) {
  let query = {
    "insert into products (title,quantity,location,urgent) values ($1,$2,$3,$4) returning *"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use title <- decode.field(1, decode.string)
    use quantity <- decode.field(1, decode.int)
    use location <- decode.field(3, decode.optional(decode.string))
    use urgent <- decode.field(4, decode.bool)
    use bought_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())

    decode.success(product_model.Product(
      id:,
      title:,
      quantity:,
      location:,
      urgent:,
      bought_at:,
      created_at:,
      updated_at:,
    ))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(title))
    |> pog.parameter(pog.int(quantity))
    |> pog.parameter(pog.nullable(fn(e) { pog.text(e) }, location))
    |> pog.parameter(pog.bool(urgent))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, products)) -> {
      Ok(products)
    }
    Error(_e) -> {
      Error(error.Internal(msg: "creating products failed"))
    }
  }
}

pub fn create_bought_at(db: pog.Connection, product_id: Int) {
  let query = {
    "update products set bought_at = now() where id = $1 returning *"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use title <- decode.field(1, decode.string)
    use quantity <- decode.field(2, decode.int)
    use location <- decode.field(3, decode.optional(decode.string))
    use urgent <- decode.field(4, decode.bool)
    use bought_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())

    decode.success(product_model.Product(
      id:,
      title:,
      quantity:,
      location:,
      urgent:,
      bought_at:,
      created_at:,
      updated_at:,
    ))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.int(product_id))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, [product, ..])) -> {
      Ok(product)
    }
    _ -> {
      Error(error.Internal(msg: "creating bought at to product failed"))
    }
  }
}

pub fn delete_bought_at(db: pog.Connection, product_id: Int) {
  let query = {
    "update products set bought_at = null where id = $1 returning *"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use title <- decode.field(1, decode.string)
    use quantity <- decode.field(2, decode.int)
    use location <- decode.field(3, decode.optional(decode.string))
    use urgent <- decode.field(4, decode.bool)
    use bought_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, pog.timestamp_decoder())
    use updated_at <- decode.field(7, pog.timestamp_decoder())

    decode.success(product_model.Product(
      id:,
      title:,
      quantity:,
      location:,
      urgent:,
      bought_at:,
      created_at:,
      updated_at:,
    ))
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.int(product_id))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, [product, ..])) -> {
      Ok(product)
    }
    _ -> {
      Error(error.Internal(msg: "deleting bought at to product failed"))
    }
  }
}
