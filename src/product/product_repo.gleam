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
    use user_id <- decode.field(1, decode.int)
    use title <- decode.field(2, decode.string)
    use quantity <- decode.field(3, decode.int)
    use location <- decode.field(4, decode.optional(decode.string))
    use urgent <- decode.field(5, decode.bool)
    use bought_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(7, pog.timestamp_decoder())
    use updated_at <- decode.field(8, pog.timestamp_decoder())

    decode.success(product_model.Product(
      id:,
      user_id:,
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

  let row_decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.int)
    use title <- decode.field(2, decode.string)
    use quantity <- decode.field(3, decode.int)
    use location <- decode.field(4, decode.optional(decode.string))
    use urgent <- decode.field(5, decode.bool)
    use bought_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(7, pog.timestamp_decoder())
    use updated_at <- decode.field(8, pog.timestamp_decoder())

    decode.success(product_model.Product(
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

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(title))
    |> pog.parameter(pog.int(quantity))
    |> pog.parameter(pog.nullable(fn(e) { pog.text(e) }, location))
    |> pog.parameter(pog.bool(urgent))
    |> pog.parameter(pog.int(user_id))
    |> pog.returning(row_decoder)
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_rows, products)) -> {
      Ok(products)
    }
    Error(_) -> {
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
    use user_id <- decode.field(1, decode.int)
    use title <- decode.field(2, decode.string)
    use quantity <- decode.field(3, decode.int)
    use location <- decode.field(4, decode.optional(decode.string))
    use urgent <- decode.field(5, decode.bool)
    use bought_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(7, pog.timestamp_decoder())
    use updated_at <- decode.field(8, pog.timestamp_decoder())

    decode.success(product_model.Product(
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
    use user_id <- decode.field(1, decode.int)
    use title <- decode.field(2, decode.string)
    use quantity <- decode.field(3, decode.int)
    use location <- decode.field(4, decode.optional(decode.string))
    use urgent <- decode.field(5, decode.bool)
    use bought_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(7, pog.timestamp_decoder())
    use updated_at <- decode.field(8, pog.timestamp_decoder())

    decode.success(product_model.Product(
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
    Ok(pog.Returned(_rows, [fun_facts, ..])) -> {
      Ok(fun_facts)
    }
    _ -> Error(error.Internal(msg: "fetching products stats failed"))
  }
}
