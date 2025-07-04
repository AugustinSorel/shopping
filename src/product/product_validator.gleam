import app/validator
import gleam/option
import valid

pub type Fields {
  Title
  Quantity
  Location
  Urgent
  Id
}

pub fn name() {
  let error = fn(msg) { #(Title, msg) }

  validator.trim
  |> valid.then(valid.string_is_not_empty(error("Title is required")))
  |> valid.then(valid.string_min_length(
    3,
    error("product name must be at least 3 characters"),
  ))
  |> valid.then(valid.string_max_length(
    255,
    error("product name must be at most 255 characters"),
  ))
  |> validator.string_required(error("title is required"))
}

pub fn quantity() {
  let error = fn(msg) { #(Quantity, msg) }

  validator.trim
  |> validator.pipe_str_to_int(
    valid.string_is_int(error("quantity must of type int")),
  )
  |> valid.then(valid.int_min(1, error("quantity must be at least 1")))
  |> valid.then(valid.int_max(255, error("quantity must be at most 255")))
  |> validator.default(1)
}

pub fn urgent() {
  let error = fn(msg) { #(Urgent, msg) }

  validator.trim
  |> validator.pipe_str_to_bool(
    validator.string_is_bool(error("urgent must be of type bool")),
  )
  |> validator.default(False)
}

pub fn location() {
  let error = fn(msg) { #(Location, msg) }

  validator.empty_str_as_none()
  |> valid.then(
    validator.trim
    |> valid.then(valid.string_is_not_empty(error("location is required")))
    |> valid.then(valid.string_min_length(
      3,
      error("location must be at least 3 characters"),
    ))
    |> valid.then(valid.string_max_length(
      255,
      error("location must be at most 255 characters"),
    ))
    |> valid.optional,
  )
}

pub fn id() {
  let error = fn(msg) { #(Id, msg) }

  validator.trim
  |> validator.pipe_str_to_int(
    valid.string_is_int(error("id must of type int")),
  )
  |> valid.then(valid.int_min(0, error("id must be at least 1")))
}

pub type CreateInput {
  CreateInput(
    title: option.Option(String),
    quantity: option.Option(String),
    location: option.Option(String),
    urgent: option.Option(String),
  )
}

pub type CreateOutput {
  CreateOutput(
    title: String,
    quantity: Int,
    location: option.Option(String),
    urgent: Bool,
  )
}

pub fn create(input: CreateInput) {
  use title <- valid.check(input.title, name())
  use quantity <- valid.check(input.quantity, quantity())
  use location <- valid.check(input.location, location())
  use urgent <- valid.check(input.urgent, urgent())

  valid.ok(CreateOutput(title:, quantity:, location:, urgent:))
}

pub fn id_str(input: String) {
  use id <- valid.check(input, id())

  valid.ok(id)
}
