import app/env
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

  let env = env.load()

  let db =
    pog.default_config()
    |> pog.host(env.db_host)
    |> pog.password(option.Some(env.db_password))
    |> pog.user(env.db_user)
    |> pog.database(env.db_name)
    |> pog.port(env.db_port)
    |> pog.pool_size(15)
    |> pog.connect

  let ctx = web.Ctx(db:, env:, user_id: option.None)

  let secret = wisp.random_string(64)

  let assert Ok(_) =
    router.handle_request(_, ctx)
    |> wisp_mist.handler(secret)
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}
