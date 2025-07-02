import app/validator
import gleam/option
import valid

pub type Product {
  Product(
    title: String,
    quantity: Int,
    location: option.Option(String),
    urgent: Bool,
  )
}

pub type Fields {
  Title
  Quantity
  Location
  Urgent
}

fn name_validator() {
  validator.trim()
  |> valid.then(valid.string_is_not_empty(#(Title, "Title is required")))
  |> valid.then(
    valid.string_min_length(3, #(
      Title,
      "product name must be at least 3 characters",
    )),
  )
  |> valid.then(
    valid.string_max_length(255, #(
      Title,
      "product name must be at most 255 characters",
    )),
  )
}

fn quantity_validator() {
  valid.string_is_int(#(Quantity, "quantity must of type int"))
  |> valid.then(valid.int_min(1, #(Quantity, "quantity must be at least 1")))
  |> valid.then(valid.int_max(255, #(Quantity, "quantity must be at most 255")))
}

fn urgent_validator() {
  validator.string_is_bool(#(Urgent, "urgent must be of type bool"))
}

fn location_validator() {
  validator.trim()
  |> valid.optional
  |> valid.then(validator.empty_str_as_none())
  |> valid.then(
    valid.string_is_not_empty(#(Location, "location is required"))
    |> valid.then(
      valid.string_min_length(3, #(
        Location,
        "location must be at least 3 characters",
      )),
    )
    |> valid.then(
      valid.string_max_length(255, #(
        Location,
        "location must be at most 255 characters",
      )),
    )
    |> valid.optional,
  )
}

pub type Create {
  Create(
    name: String,
    quantity: String,
    location: option.Option(String),
    urgent: String,
  )
}

pub fn create_product(input: Create) {
  use title <- valid.check(input.name, name_validator())
  use quantity <- valid.check(input.quantity, quantity_validator())
  use location <- valid.check(input.location, location_validator())
  use urgent <- valid.check(input.urgent, urgent_validator())

  valid.ok(Product(title:, quantity:, location:, urgent:))
}
