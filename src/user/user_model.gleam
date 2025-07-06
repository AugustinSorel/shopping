import pog

pub type User {
  User(
    id: Int,
    email: String,
    password: String,
    created_at: pog.Timestamp,
    updated_at: pog.Timestamp,
  )
}

pub type CtxUser {
  CtxUser(id: Int)
}
