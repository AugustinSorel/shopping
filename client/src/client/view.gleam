import client/icon
import client/styles
import glailwind_merge
import gleam/bool
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html

pub type Variant {
  Default
  Ghost
  Destructive
}

pub type Size {
  Medium
}

pub fn button(
  variant: Variant,
  size: Size,
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  let base_class = {
    "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors gap-2 focus-visible:outline-hidden focus-visible:ring-2 focus:ring-ring focus-visible:ring-offset-2 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
  }

  let variant_class = case variant {
    Default -> {
      "bg-primary text-on-primary hover:bg-primary/90 font-bold focus-visible:ring-primary"
    }
    Ghost -> "hover:bg-accent hover:text-accent-foreground"
    Destructive -> {
      "bg-error text-on-error hover:bg-error/90 font-bold focus-visible:ring-error"
    }
  }

  let size_class = case size {
    Medium -> "h-10 px-4 py-2 rounded-md"
  }

  let attr_class = styles.extract_class(attr)

  let class = {
    glailwind_merge.tw_merge([base_class, variant_class, size_class, attr_class])
  }

  html.button([attribute.class(class), ..attr], children)
}

pub fn alert(
  variant: Variant,
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  let base_class = {
    "relative w-full p-4 [&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg+div]:translate-y-[-3px] [&:has(svg)]:pl-11 rounded-lg border"
  }

  let variant_class = case variant {
    Default | Ghost -> "border-border text-foreground"
    Destructive -> {
      "border-error text-on-error-container [&>svg]:text-on-error-container bg-error-container"
    }
  }

  let attr_class = styles.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, variant_class, attr_class])

  html.div([attribute.role("alert"), attribute.class(class), ..attr], children)
}

pub fn alert_title(
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  html.h5(
    [attribute.class("mb-1 font-medium leading-none tracking-tight"), ..attr],
    children,
  )
}

pub fn alert_description(
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  html.div([attribute.class("[&_p]:leading-relaxed text-sm"), ..attr], children)
}

pub fn checkbox(attr: List(attribute.Attribute(msg))) {
  let base_class = {
    "checked:bg-primary shrink-0 focus-visible:ring-on-surface before:bg-on-primary text-on-surface border-outline flex size-4 cursor-pointer appearance-none items-center justify-center rounded-sm border-2 before:hidden before:size-2.5 before:[clip-path:polygon(14%_44%,0_65%,50%_100%,100%_16%,80%_0%,43%_62%)] checked:border-none checked:before:block focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50"
  }

  let attr_class = styles.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, attr_class])

  html.input([attribute.type_("checkbox"), attribute.class(class), ..attr])
}

pub fn input(attr: List(attribute.Attribute(msg))) {
  let base_class = {
    "ring-offset-background bg-surface-container-lowest focus-visible:ring-outline border-outline rounded-md border-2 px-5 py-2 focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50"
  }

  let attr_class = styles.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, attr_class])

  html.input([attribute.class(class), ..attr])
}

pub fn avatar(value: String) {
  let initial = string.first(value) |> result.unwrap("?")

  let hue = styles.hue_from_string(initial)

  html.span(
    [
      attribute.data("initial", initial),
      attribute.class(
        "font-semibold capitalize relative isolate shrink-0 flex size-12 items-center justify-center overflow-hidden rounded-full text-xl after:absolute after:-z-10 after:text-3xl after:blur-lg after:content-[attr(data-initial)]",
      ),
      attribute.styles([
        #(
          "background",
          "light-dark(hsl(" <> hue <> " 50% 98%), hsl(" <> hue <> " 50% 6%))",
        ),
        #(
          "color",
          "light-dark(hsl(" <> hue <> " 50% 40%), hsl(" <> hue <> " 50% 60%))",
        ),
      ]),
    ],
    [html.text(initial)],
  )
}

pub fn footer(current_path: String, is_signed_in: option.Option(Nil)) {
  use <- bool.guard(when: option.is_none(is_signed_in), return: element.none())

  html.footer(
    [
      attribute.class(
        "bg-surface-container sm:max-w-app sm:w-app text-on-surface-variant fixed right-0 bottom-0 left-0 flex w-full justify-around sm:left-[max(calc((100%-var(--max-width-app))/2),0rem)] sm:justify-evenly sm:rounded-t-xl",
      ),
    ],
    [
      html.a(
        [
          attribute.class(
            "group flex cursor-pointer flex-col items-center py-4 text-sm",
          ),
          attribute.href("/products"),
          attribute.aria_current(
            bool.to_string(current_path == "/products") |> string.lowercase,
          ),
        ],
        [
          html.span(
            [
              attribute.class(
                "group-hover:bg-surface-container-highest group-aria-[current='true']:bg-secondary-container flex w-full justify-center rounded-full px-6 py-2 transition-colors",
              ),
            ],
            [
              icon.home([
                attribute.class("group-aria-[current='true']:fill-current"),
              ]),
            ],
          ),
          html.span([attribute.class("first-letter:capitalize")], [
            html.text("home"),
          ]),
        ],
      ),
      html.a(
        [
          attribute.class(
            "group flex cursor-pointer flex-col items-center py-4 text-sm",
          ),
          attribute.href("/products/create"),
          attribute.aria_current(
            bool.to_string(current_path == "/products/create")
            |> string.lowercase,
          ),
        ],
        [
          html.span(
            [
              attribute.class(
                "group-hover:bg-surface-container-highest group-aria-[current='true']:bg-secondary-container flex w-full justify-center rounded-full px-6 py-2 transition-colors",
              ),
            ],
            [
              icon.circle_plus([
                attribute.class(
                  "group-aria-[current='true']:[&_path]:stroke-surface-container group-aria-[current='true']:fill-current",
                ),
              ]),
            ],
          ),
          html.span([attribute.class("first-letter:capitalize")], [
            html.text("add"),
          ]),
        ],
      ),
      html.a(
        [
          attribute.class(
            "group flex cursor-pointer flex-col items-center py-4 text-sm",
          ),
          attribute.href("/users/account"),
          attribute.aria_current(
            bool.to_string(current_path == "/users/account")
            |> string.lowercase,
          ),
        ],
        [
          html.span(
            [
              attribute.class(
                "group-hover:bg-surface-container-highest group-aria-[current='true']:bg-secondary-container flex w-full justify-center rounded-full px-6 py-2 transition-colors",
              ),
            ],
            [
              icon.user([
                attribute.class("group-aria-[current='true']:fill-current"),
              ]),
            ],
          ),
          html.span([attribute.class("first-letter:capitalize")], [
            html.text("account"),
          ]),
        ],
      ),
    ],
  )
}

const theme_key = "theme"

pub fn load_theme_script() {
  html.script([], "
    const cachedTheme = localStorage.getItem('" <> theme_key <> "');

    if (cachedTheme) {
      document.documentElement.dataset['" <> theme_key <> "'] = cachedTheme;
    }
 ")
}

pub fn theme_switcher() {
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

pub fn spinner(attr: List(attribute.Attribute(msg)), size: icon.Size) {
  icon.spinner([attribute.class("animate-spin"), ..attr], size)
}
