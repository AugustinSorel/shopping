import gleam/time/timestamp

pub type CtxUser {
  CtxUser(id: Int, email: String)
}

pub type CtxSession {
  CtxSession(
    id: String,
    last_verified_at: timestamp.Timestamp,
    secret_hash: BitArray,
    user: CtxUser,
  )
}
