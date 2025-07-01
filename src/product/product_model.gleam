import gleam/option
import pog

pub type Product {
  Product(
    id: Int,
    title: String,
    quantity: Int,
    bought_at: option.Option(Int),
    created_at: pog.Timestamp,
    updated_at: pog.Timestamp,
  )
}
