import gleam/list
import lustre/attribute
import lustre/element/html

const theme_key = "theme"

pub fn blocking_script() {
  html.script([], "
    const cachedTheme = localStorage.getItem('" <> theme_key <> "');

    if (cachedTheme) {
      document.documentElement.dataset['" <> theme_key <> "'] = cachedTheme;
    }
 ")
}

pub fn switcher() {
  html.fieldset(
    [
      attribute.class("flex items-center gap-0.5 noscript:hidden"),
      attribute.attribute("_", "
        init
          set :system_theme_input to the first <input[value='auto']/>
          set :theme_key to '" <> theme_key <> "'
          set :x to 10

          get localStorage[:theme_key] then
            set selected_theme to it or :system_theme_input.value
            add @checked to the first <input[value=$selected_theme]/> in me
          end

        on change
          if target.value is :system_theme_input.value then
            remove @data-theme from <html/>
            localStorage.removeItem(:theme_key)
          otherwise
            set <html/>'s @data-theme to target.value
            set localStorage[:theme_key] to target.value
          end
      "),
    ],
    [
      html.legend([attribute.class("sr-only")], [html.text("Theme:")]),
      ..list.map(["auto", "light", "dark"], item)
    ],
  )
}

fn item(value: String) {
  html.label(
    [
      attribute.class(
        "bg-secondary-container hover:bg-secondary-container/80 text-on-secondary-container has-checked:bg-secondary has-checked:text-on-secondary has-focus-visible:ring-secondary ring-offset-surface-container hover:has-checked:bg-secondary/80 cursor-pointer rounded-sm px-6 py-2 first-of-type:rounded-l-2xl last-of-type:rounded-r-2xl has-checked:rounded-2xl has-focus-visible:z-10 has-focus-visible:ring-2 has-focus-visible:ring-offset-2 has-focus-visible:outline-none has-disabled:pointer-events-none has-disabled:opacity-50",
      ),
      attribute.attribute(
        "_",
        "on load wait 500ms then add .transition-all to me",
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
