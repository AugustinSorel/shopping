import gleam/option

pub type CreateProductInput {
  CreateProductInput(
    title: String,
    quantity: Int,
    location: option.Option(String),
    urgent: Bool,
  )
}
