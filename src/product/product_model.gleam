import gleam/option
import gleam/time/timestamp

pub type Product {
  Product(
    id: Int,
    title: String,
    quantity: Int,
    urgent: Bool,
    location: option.Option(String),
    bought_at: option.Option(timestamp.Timestamp),
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
  )
}
