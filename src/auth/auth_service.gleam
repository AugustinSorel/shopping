import antigone
import gleam/crypto

pub fn sha512_hash(secret: BitArray) {
  crypto.hash(crypto.Sha512, secret)
}

pub fn sha512_compare(left: BitArray, right: BitArray) {
  crypto.secure_compare(left, right)
}

pub fn hash_secret(secret: BitArray) {
  antigone.hash(antigone.hasher(), secret)
}

pub fn hash_verify(left: BitArray, right: String) {
  antigone.verify(left, right)
}
