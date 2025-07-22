pub type SignUpInput {
  SignUpInput(email: String, password: String, confirm_password: String)
}

pub type SignInInput {
  SignInInput(email: String, password: String)
}
