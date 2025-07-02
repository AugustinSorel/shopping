import gleam/option
import pog

pub type Product {
  Product(
    id: Int,
    title: String,
    quantity: Int,
    urgent: Bool,
    location: option.Option(String),
    bought_at: option.Option(pog.Timestamp),
    created_at: pog.Timestamp,
    updated_at: pog.Timestamp,
  )
}
