import gleam/dynamic/decode
import pog
import product/product_model

pub fn get_all(db: pog.Connection) {
  let query = "select * from products"

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use title <- decode.field(1, decode.string)
    use quantity <- decode.field(2, decode.int)
    use urgent <- decode.field(3, decode.bool)
    use location <- decode.field(4, decode.optional(decode.string))
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
    Error(err) -> {
      Error(err)
    }
  }
}

pub fn create(db: pog.Connection, title: String, quantity: Int, urgent: Bool) {
  let query = {
    "insert into products (title,quantity,urgent) values ($1,$2,$3) returning *"
  }

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use title <- decode.field(1, decode.string)
    use quantity <- decode.field(2, decode.int)
    use urgent <- decode.field(3, decode.bool)
    use location <- decode.field(4, decode.optional(decode.string))
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
    |> pog.parameter(pog.text(title))
    |> pog.parameter(pog.int(quantity))
    |> pog.parameter(pog.bool(urgent))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, products)) -> {
      Ok(products)
    }
    Error(err) -> {
      Error(err)
    }
  }
}
