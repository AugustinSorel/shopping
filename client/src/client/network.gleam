pub type State(data) {
  Idle
  Err(msg: String)
  Success(data: data)
  Loading
}
