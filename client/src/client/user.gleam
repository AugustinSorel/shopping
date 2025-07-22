import client/icon
import client/network
import client/theme
import client/view
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event
import shared/context

pub fn account_view(children: List(element.Element(a)), user: context.User) {
  html.main([attribute.class("max-w-app mx-auto space-y-10")], [
    html.header(
      [
        attribute.class(
          "max-w-app mx-auto my-4 flex items-center gap-3 sm:my-10",
        ),
      ],
      [
        view.avatar(user.email),
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

pub fn preference(
  on_theme_change on_theme_change: fn(theme.Theme) -> a,
  sign_out_state sign_out_state: network.State(a),
  sign_out_on_submit sign_out_on_submit,
) {
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
          html.dd([], [theme.theme_switcher(on_theme_change:)]),
          html.dt([], [html.text("session")]),
          html.dd([], [
            view.button(
              view.Ghost,
              view.Medium,
              [
                event.on_click(sign_out_on_submit),
                attribute.class(
                  "text-error text-md hover:bg-error-container text-md",
                ),
              ],
              [
                html.text("sign out"),
                {
                  case sign_out_state {
                    network.Loading -> view.spinner([], icon.Small)
                    _ -> element.none()
                  }
                },
              ],
            ),
          ]),
        ],
      ),
    ],
  )
}
