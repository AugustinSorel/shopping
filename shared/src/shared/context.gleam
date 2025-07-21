import gleam/dynamic/decode
import gleam/json

pub type User {
  User(id: Int, email: String)
}

pub type Session {
  Session(id: String, user: User)
}

pub fn decode_session(json_session: String) {
  json.parse(json_session, {
    use id <- decode.field("id", decode.string)
    use user_id <- decode.subfield(["user", "id"], decode.int)
    use email <- decode.subfield(["user", "email"], decode.string)

    decode.success(Session(id:, user: User(id: user_id, email:)))
  })
}

pub fn encode_session(session: Session) {
  json.object([
    #("id", json.string(session.id)),
    #(
      "user",
      json.object([
        #("id", json.int(session.user.id)),
        #("email", json.string(session.user.email)),
      ]),
    ),
  ])
  |> json.to_string
}
