pub type User {
  User(id: Int, email: String)
}

pub type Session {
  Session(id: String, user: User)
}
