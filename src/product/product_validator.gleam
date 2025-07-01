import app/validator
import valid

pub type Product {
  Product(name: String, quantity: Int, urgent: Bool)
}

pub type Fields {
  Name
  Quantity
  Urgent
}

fn name_validator() {
  valid.string_is_not_empty(#(Name, "Name is required"))
  |> valid.then(
    valid.string_min_length(3, #(
      Name,
      "product name must be at least 3 characters",
    )),
  )
  |> valid.then(
    valid.string_max_length(255, #(
      Name,
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

pub type Create {
  Create(name: String, quantity: String, urgent: String)
}

pub fn create_product(input: Create) {
  use name <- valid.check(input.name, name_validator())
  use quantity <- valid.check(input.quantity, quantity_validator())
  use urgent <- valid.check(input.urgent, urgent_validator())

  valid.ok(Product(name:, quantity:, urgent:))
}
