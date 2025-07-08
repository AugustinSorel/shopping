import app/validator
import gleam/option
import gleam/order
import gleam/string
import valid

pub type Fields {
  Email
  Password
  ConfirmPassword
}

pub fn email() {
  let error = fn(msg) { #(Email, msg) }

  validator.trim
  |> valid.then(valid.string_is_not_empty(error("email is required")))
  |> valid.then(valid.string_is_email(error("email must be valid")))
  |> valid.then(valid.string_min_length(
    3,
    error("email must be at least 3 characters"),
  ))
  |> valid.then(valid.string_max_length(
    255,
    error("email must be at most 255 characters"),
  ))
  |> validator.string_required(error("email is required"))
}

pub fn password() {
  let error = fn(msg) { #(Password, msg) }

  validator.trim
  |> valid.then(valid.string_is_not_empty(error("password is required")))
  |> valid.then(valid.string_min_length(
    3,
    error("password must be at least 3 characters"),
  ))
  |> valid.then(valid.string_max_length(
    255,
    error("password must be at most 255 characters"),
  ))
  |> validator.string_required(error("password is required"))
}

pub fn confirm_password(password: String) {
  fn(confirm_password: option.Option(String)) {
    let confirm_password = option.unwrap(confirm_password, "")

    case string.compare(password, confirm_password) {
      order.Eq -> #(password, [])
      _ -> #(password, [#(ConfirmPassword, "password don't match")])
    }
  }
}

pub type SignUpInput {
  SignUpInput(
    email: option.Option(String),
    password: option.Option(String),
    confirm_password: option.Option(String),
  )
}

pub type SignUpOutput {
  SignUpOutput(email: String, password: String, confirm_password: String)
}

pub fn sign_up(input: SignUpInput) {
  use email <- valid.check(input.email, email())
  use password <- valid.check(input.password, password())
  use confirm_password <- valid.check(
    input.confirm_password,
    confirm_password(password),
  )

  valid.ok(SignUpOutput(email:, password:, confirm_password:))
}

pub type SignInInput {
  SignInInput(email: option.Option(String), password: option.Option(String))
}

pub type SignInOutput {
  SignInOutput(email: String, password: String)
}

pub fn sign_in(input: SignInInput) {
  use email <- valid.check(input.email, email())
  use password <- valid.check(input.password, password())

  valid.ok(SignInOutput(email:, password:))
}
