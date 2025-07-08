import gleam/time/timestamp

pub type Session {
  Session(
    id: String,
    user_id: Int,
    secret_hash: BitArray,
    last_verified_at: timestamp.Timestamp,
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
  )
}

pub type DecodedToken {
  DecodedToken(session_id: String, session_secret: String)
}
