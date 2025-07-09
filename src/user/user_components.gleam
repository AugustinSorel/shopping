import components/button
import components/icon
import components/spinner
import components/theme
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import user/user_model

fn char_to_int(char: String) -> Int {
  case string.to_utf_codepoints(char) {
    [codepoint] -> string.utf_codepoint_to_int(codepoint)
    _ -> 0
  }
}

fn get_hue_from_string(input: String) -> String {
  let input_as_int = {
    string.to_graphemes(input)
    |> list.fold(0, fn(prev, curr) { prev + char_to_int(curr) })
  }

  let hue = int.bitwise_shift_left(input_as_int, 5)

  int.to_string(hue)
}

pub fn avatar(name: String) {
  let initial = string.first(name) |> result.unwrap("?")

  html.span(
    [
      attribute.data("initial", initial),
      attribute.class(
        "font-semibold capitalize relative isolate shrink-0 flex size-12 items-center justify-center overflow-hidden rounded-full text-xl after:absolute after:-z-10 after:text-3xl after:blur-lg after:content-[attr(data-initial)]",
      ),
      attribute.styles([
        #(
          "background",
          string.concat(["hsl(", get_hue_from_string(initial), ",50%,98%)"]),
        ),
        #(
          "color",
          string.concat(["hsl(", get_hue_from_string(initial), ",50%,40%)"]),
        ),
      ]),
    ],
    [html.text(initial)],
  )
}

pub fn account_page(
  children: List(element.Element(msg)),
  user: user_model.CtxUser,
) {
  html.main([attribute.class("max-w-app mx-auto space-y-10")], [
    html.header(
      [
        attribute.class(
          "max-w-app mx-auto my-4 flex items-center gap-3 sm:my-10",
        ),
      ],
      [
        avatar(user.email),
        html.h2(
          [
            attribute.class(
              "text-2xl font-semibold first-letter:capitalize truncate",
            ),
          ],
          [html.text(user.email)],
        ),
      ],
    ),
    ..children
  ])
}

pub fn fun_facts() {
  html.section(
    [attribute.class("bg-surface-container-lowest space-y-3 rounded-3xl p-6")],
    [
      html.h2(
        [attribute.class("text-lg font-semibold first-letter:capitalize")],
        [html.text("info:")],
      ),
      html.dl(
        [
          attribute.class(
            "grid grid-cols-[1fr_auto] [&>dt]:first-letter:capitalize",
          ),
        ],
        [
          html.dt([], [html.text("products created by you")]),
          html.dd([], [html.text("0")]),
          html.dt([], [html.text("total products")]),
          html.dd([], [html.text("0")]),
        ],
      ),
    ],
  )
}

pub fn preference() {
  html.section(
    [attribute.class("bg-surface-container-lowest space-y-3 rounded-3xl p-6")],
    [
      html.h2(
        [attribute.class("text-lg font-semibold first-letter:capitalize")],
        [html.text("preference:")],
      ),
      html.dl(
        [
          attribute.class(
            "grid grid-cols-[1fr_auto] items-center gap-y-3 [&>dd]:ml-auto [&>dt]:first-letter:capitalize",
          ),
        ],
        [
          html.dt([], [html.text("theme")]),
          html.dd([], [theme.switcher()]),
          html.dt([], [html.text("session")]),
          html.dd([], [
            button.component(
              button.Ghost,
              button.Medium,
              [
                attribute.attribute("hx-post", "/sign-out"),
                attribute.attribute("hx-target", "closest section"),
                attribute.attribute("hx-swap", "outerHTML"),
                attribute.attribute("hx-disabled-elt", "this"),
                attribute.class(
                  "text-error text-md hover:bg-error-container text-md",
                ),
              ],
              [html.text("sign out"), spinner.component([], icon.Small)],
            ),
          ]),
        ],
      ),
    ],
  )
}
