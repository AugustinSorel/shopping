import components/icon
import gleam/bool
import gleam/string
import lustre/attribute
import lustre/element/html

pub fn component(current_path: String) {
  echo current_path
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
