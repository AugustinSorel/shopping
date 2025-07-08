import gleam/time/timestamp

pub type User {
  User(
    id: Int,
    email: String,
    password: String,
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
  )
}

pub type CtxUser {
  CtxUser(id: Int)
}
