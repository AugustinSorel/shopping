import dot_env
import dot_env/env

pub type Env {
  Env(
    db_user: String,
    db_password: String,
    db_host: String,
    db_name: String,
    db_port: Int,
  )
}

pub fn load() {
  dot_env.load_default()

  let assert Ok(db_user) = env.get_string("DB_USER")
  let assert Ok(db_password) = env.get_string("DB_PASSWORD")
  let assert Ok(db_host) = env.get_string("DB_HOST")
  let assert Ok(db_name) = env.get_string("DB_NAME")
  let assert Ok(db_port) = env.get_int("DB_PORT")

  Env(db_user:, db_password:, db_host:, db_name:, db_port:)
}
