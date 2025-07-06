import pog

pub type Session {
  Session(
    id: String,
    user_id: Int,
    secret_hash: BitArray,
    last_verified_at: pog.Timestamp,
    created_at: pog.Timestamp,
    updated_at: pog.Timestamp,
  )
}

pub type DecodedToken {
  DecodedToken(session_id: String, session_secret: String)
}
