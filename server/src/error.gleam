import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/result
import wisp

pub type Validation {
  Validation(field: String, msg: String)
}

pub type Error {
  UserValidation(errors: List(Validation))
  UserNotFound
  UserConflict
  SessionNotFound
  Internal(msg: String)
}

//TODO: refactor this
pub fn build_response(error: Error) {
  case error {
    Internal(msg:) -> {
      json.object([#("message", json.string(msg))])
      |> json.to_string_tree
      |> wisp.json_response(wisp.internal_server_error().status)
    }
    UserValidation(errors) -> {
      json.object([
        #("message", json.string("user validation failed")),
        #(
          "errors",
          json.array(errors, fn(error) {
            json.object([
              #("field", json.string(error.field)),
              #("message", json.string(error.msg)),
            ])
          }),
        ),
      ])
      |> json.to_string_tree
      |> wisp.json_response(wisp.unprocessable_entity().status)
    }
    UserNotFound -> {
      json.object([#("message", json.string("user not found"))])
      |> json.to_string_tree
      |> wisp.json_response(wisp.not_found().status)
    }
    UserConflict -> {
      json.object([#("message", json.string("email already used"))])
      |> json.to_string_tree
      |> wisp.json_response(409)
    }
    SessionNotFound -> todo
  }
}

pub fn decode_to_validation(errors) {
  list.map(errors, fn(e) {
    case e {
      decode.DecodeError(expected:, found:, path:) -> {
        let field = list.first(path) |> result.unwrap("unknown")
        let msg = case found {
          "Nothing" -> field <> " is required"
          _ -> expected <> " but found " <> found
        }

        Validation(field:, msg:)
      }
    }
  })
}
