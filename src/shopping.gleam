import app/env
import app/router
import app/web
import gleam/erlang/process
import gleam/option
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision
import mist
import pog
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let env = env.load()

  let db_name = process.new_name("db")
  let db = pog.named_connection(db_name)

  let db_supervisor = {
    pog.default_config(db_name)
    |> pog.host(env.db_host)
    |> pog.password(option.Some(env.db_password))
    |> pog.user(env.db_user)
    |> pog.database(env.db_name)
    |> pog.port(env.db_port)
    |> pog.pool_size(15)
    |> pog.supervised
  }

  let ctx = web.Ctx(db:, env:, session: option.None)

  let secret = wisp.random_string(64)

  let http_server_supervisor = {
    supervision.supervisor(fn() {
      router.handle_request(_, ctx)
      |> wisp_mist.handler(secret)
      |> mist.new
      |> mist.port(8080)
      |> mist.start
    })
  }

  let _supervisor =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(db_supervisor)
    |> supervisor.add(http_server_supervisor)
    |> supervisor.start

  process.sleep_forever()
}
