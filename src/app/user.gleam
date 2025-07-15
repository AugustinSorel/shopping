import app/error
import app/icon
import app/view
import app/web
import gleam/dynamic/decode
import gleam/time/timestamp
import lustre/attribute
import lustre/element
import lustre/element/html
import pog

pub type User {
  User(
    id: Int,
    email: String,
    password: String,
    created_at: timestamp.Timestamp,
    updated_at: timestamp.Timestamp,
  )
}

pub fn create(email: String, password: String, db: pog.Connection) {
  let query = {
    "insert into users (email, password) VALUES ($1, $2) returning *"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(email))
    |> pog.parameter(pog.text(password))
    |> pog.returning(user_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [user, ..])) -> Ok(user)
    Ok(pog.Returned(_i, [])) -> Error(error.UserNotFound)
    Error(pog.ConstraintViolated(_, _, _)) -> Error(error.UserConflict)
    Error(_) -> Error(error.Internal("creating user failed"))
  }
}

pub fn get_by_email(email: String, db: pog.Connection) {
  let query = {
    "select * from users where email = $1"
  }

  let response =
    pog.query(query)
    |> pog.parameter(pog.text(email))
    |> pog.returning(user_row_decoder())
    |> pog.execute(db)

  case response {
    Ok(pog.Returned(_i, [user, ..])) -> Ok(user)
    Ok(pog.Returned(_i, [])) -> Error(error.UserNotFound)
    Error(_) -> Error(error.Internal(msg: "fetching user by email failed"))
  }
}

fn user_row_decoder() {
  use id <- decode.field(0, decode.int)
  use email <- decode.field(1, decode.string)
  use password <- decode.field(2, decode.string)
  use created_at <- decode.field(3, pog.timestamp_decoder())
  use updated_at <- decode.field(4, pog.timestamp_decoder())

  decode.success(User(id:, email:, password:, created_at:, updated_at:))
}

pub fn account_page(children: List(element.Element(msg)), user: web.CtxUser) {
  html.main([attribute.class("max-w-app mx-auto space-y-10")], [
    html.header(
      [
        attribute.class(
          "max-w-app mx-auto my-4 flex items-center gap-3 sm:my-10",
        ),
      ],
      [
        view.avatar(user.email),
        html.h2(
          [
            attribute.class(
              "text-2xl font-semibold first-letter:capitalize truncate",
            ),
          ],
          [html.text(user.email)],
        ),
      ],
    ),
    ..children
  ])
}

pub fn preference() {
  html.section(
    [attribute.class("bg-surface-container-lowest space-y-3 rounded-3xl p-6")],
    [
      html.h2(
        [attribute.class("text-lg font-semibold first-letter:capitalize")],
        [html.text("preference:")],
      ),
      html.dl(
        [
          attribute.class(
            "grid grid-cols-[1fr_auto] items-center gap-y-3 [&>dd]:ml-auto [&>dt]:first-letter:capitalize",
          ),
        ],
        [
          html.dt([], [html.text("theme")]),
          html.dd([], [view.theme_switcher()]),
          html.dt([], [html.text("session")]),
          html.dd([], [
            view.button(
              view.Ghost,
              view.Medium,
              [
                attribute.attribute("hx-post", "/sign-out"),
                attribute.attribute("hx-target", "closest section"),
                attribute.attribute("hx-swap", "outerHTML"),
                attribute.attribute("hx-disabled-elt", "this"),
                attribute.class(
                  "text-error text-md hover:bg-error-container text-md",
                ),
              ],
              [html.text("sign out"), view.spinner([], icon.Small)],
            ),
          ]),
        ],
      ),
    ],
  )
}

pub fn preference_fallback(msg: String) {
  view.alert(view.Destructive, [], [
    icon.circle_alert([]),
    view.alert_title([], [html.text("Could not load preference")]),
    view.alert_description([], [html.text(msg)]),
  ])
}
