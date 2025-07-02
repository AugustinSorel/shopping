import app/router
import app/web
import gleam/erlang/process
import gleam/option
import mist
import pog
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  let db =
    pog.default_config()
    |> pog.host("localhost")
    |> pog.password(option.Some("postgres"))
    |> pog.database("gleam_shopping_plo_plo")
    |> pog.pool_size(15)
    |> pog.connect

  let ctx = web.Ctx(db:)

  let secret = wisp.random_string(64)

  let assert Ok(_) =
    router.handle_request(_, ctx)
    |> wisp_mist.handler(secret)
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}
