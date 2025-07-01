import gleam/dynamic/decode
import gleam/option
import pog
import product/product_model

pub fn get_all(db: pog.Connection) {
  let query = "select * from products"

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use title <- decode.field(1, decode.string)
    use quantity <- decode.field(2, decode.int)
    use bought_at <- decode.field(3, decode.optional(decode.int))
    use created_at <- decode.field(4, pog.timestamp_decoder())
    use updated_at <- decode.field(5, pog.timestamp_decoder())

    decode.success(product_model.Product(
      id:,
      title:,
      quantity:,
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

pub type Res {
  Res(
    purchased: option.Option(List(product_model.Product)),
    unpurchased: option.Option(List(product_model.Product)),
  )
}
