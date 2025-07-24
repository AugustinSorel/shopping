import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Model {
  Model
}

fn init(_) -> #(Model, effect.Effect(Msg)) {
  let model = Model

  #(model, effect.none())
}

pub type Msg {
  UserChangedTheme
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserChangedTheme -> {
      echo "THEME CHANGED"

      #(model, effect.none())
    }
  }
}

pub fn view(_model: Model) -> element.Element(Msg) {
  element.fragment([
    // html.div([], [
    account_view(UserChangedTheme),
    html.footer([], [html.text("footer")]),
  ])
}

fn account_view(on_theme_change) {
  html.main([attribute.class("max-w-app mx-auto space-y-10")], [
    html.button([event.on_click(on_theme_change)], [html.text("click")]),
    html.button([event.on_click(on_theme_change)], [html.text("click 2")]),
  ])
}
