import gleam/time/timestamp
import user/user_model

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

pub type SessionWithUser {
  SessionWithUser(
    id: String,
    last_verified_at: timestamp.Timestamp,
    secret_hash: BitArray,
    user: user_model.CtxUser,
  )
}

pub type DecodedToken {
  DecodedToken(session_id: String, session_secret: String)
}
