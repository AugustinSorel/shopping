import antigone
import error
import gleam/crypto
import gleam/dynamic
import gleam/dynamic/decode
import gleam/result
import shared/auth

pub fn decode_sign_up(json: dynamic.Dynamic) {
  let res = {
    decode.run(json, sign_up_decoder())
    |> result.map_error(fn(e) {
      error.UserValidation(errors: error.decode_to_validation(e))
    })
  }

  use sign_up <- result.try(res)

  Ok(sign_up)
}

pub fn decode_sign_in(json: dynamic.Dynamic) {
  let res = {
    decode.run(json, sign_in_decoder())
    |> result.map_error(fn(e) {
      error.UserValidation(errors: error.decode_to_validation(e))
    })
  }

  use sign_in <- result.try(res)

  Ok(sign_in)
}

fn sign_up_decoder() -> decode.Decoder(auth.SignUpInput) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)
  use confirm_password <- decode.field("confirm_password", decode.string)

  decode.success(auth.SignUpInput(email:, password:, confirm_password:))
}

fn sign_in_decoder() -> decode.Decoder(auth.SignInInput) {
  use email <- decode.field("email", decode.string)
  use password <- decode.field("password", decode.string)

  decode.success(auth.SignInInput(email:, password:))
}

pub fn hash_secret(secret: BitArray) {
  antigone.hash(antigone.hasher(), secret)
}

pub fn hash_verify(left: BitArray, right: String) {
  antigone.verify(left, right)
}

pub fn sha512_hash(secret: BitArray) {
  crypto.hash(crypto.Sha512, secret)
}

pub fn sha512_compare(left: BitArray, right: BitArray) {
  crypto.secure_compare(left, right)
}
