import app/router
import app/web
import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()

  let ctx = web.Ctx(static_dir: web.get_static_dir_path())

  let secret = wisp.random_string(64)

  let assert Ok(_) =
    router.handle_request(_, ctx)
    |> wisp_mist.handler(secret)
    |> mist.new
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}
