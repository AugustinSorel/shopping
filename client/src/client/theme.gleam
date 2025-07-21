import gleam/list
import gleam/result
import lustre/attribute
import lustre/element/html
import lustre/event
import plinth/javascript/storage

const theme_key = "theme"

pub type Theme {
  Light
  Dark
  Auto
}

pub fn to_string(theme: Theme) {
  case theme {
    Auto -> "auto"
    Dark -> "dark"
    Light -> "light"
  }
}

pub fn from_string(theme: String) {
  case theme {
    "dark" -> Dark
    "light" -> Light
    _ -> Auto
  }
}

pub fn load_theme_script() {
  html.script([], "
    const cachedTheme = localStorage.getItem('" <> theme_key <> "');

    if (cachedTheme) {
      document.documentElement.dataset['" <> theme_key <> "'] = cachedTheme;
    }
 ")
}

pub fn theme_switcher(on_theme_change on_theme_change: fn(Theme) -> a) {
  html.fieldset(
    [
      attribute.class("flex items-center gap-0.5 noscript:hidden"),
      event.on_change(fn(theme) {
        theme
        |> from_string()
        |> on_theme_change()
      }),
    ],
    [
      html.legend([attribute.class("sr-only")], [html.text("Theme:")]),
      ..list.map(["auto", "light", "dark"], theme_item)
    ],
  )
}

fn theme_item(value: String) {
  html.label(
    [
      attribute.class(
        "bg-secondary-container hover:bg-secondary-container/80 text-on-secondary-container has-checked:bg-secondary has-checked:text-on-secondary has-focus-visible:ring-secondary ring-offset-surface-container hover:has-checked:bg-secondary/80 cursor-pointer rounded-sm px-6 py-2 first-of-type:rounded-l-2xl last-of-type:rounded-r-2xl has-checked:rounded-2xl has-focus-visible:z-10 has-focus-visible:ring-2 has-focus-visible:ring-offset-2 has-focus-visible:outline-none has-disabled:pointer-events-none has-disabled:opacity-50",
      ),
    ],
    [
      html.input([
        attribute.class("sr-only"),
        attribute.name("theme"),
        attribute.type_("radio"),
        attribute.value(value),
      ]),
      html.text(value),
    ],
  )
}

pub fn save_to_local_storage(theme: Theme) {
  case storage.local() {
    Error(_) -> Error(Nil)
    Ok(storage) -> {
      storage.set_item(storage, theme_key, to_string(theme))
    }
  }
}

pub fn clear_local_storage() {
  case storage.local() {
    Error(_) -> Nil
    Ok(storage) -> {
      storage.remove_item(storage, theme_key)
    }
  }
}

pub fn get_from_local_storage() {
  case storage.local() {
    Error(_) -> Error(Nil)
    Ok(storage) -> {
      storage.get_item(storage, theme_key)
    }
  }
  |> result.map(from_string)
  |> result.unwrap(Auto)
}
