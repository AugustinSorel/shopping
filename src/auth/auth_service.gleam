import gleam/bit_array
import gleam/crypto

pub fn hash_secret(secret: String) {
  let secret = secret |> bit_array.from_string

  crypto.hash(crypto.Sha512, secret)
}
