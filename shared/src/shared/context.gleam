import gleam/dynamic/decode
import gleam/json

pub type User {
  User(email: String)
}

pub type Session {
  Session(id: String, user: User)
}

pub fn decode_session(json_session: String) {
  json.parse(json_session, {
    use id <- decode.field("id", decode.string)
    use email <- decode.subfield(["user", "email"], decode.string)

    decode.success(Session(id:, user: User(email:)))
  })
}

pub fn encode_session(session: Session) {
  json.object([
    #("id", json.string(session.id)),
    #("user", json.object([#("email", json.string(session.user.email))])),
  ])
  |> json.to_string
}
