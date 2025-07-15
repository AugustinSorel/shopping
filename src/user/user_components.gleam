import app/icon
import app/view
import lustre/attribute
import lustre/element
import lustre/element/html
import user/user_model

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
          html.dd([], [view.theme_switcher()]),
          html.dt([], [html.text("session")]),
          html.dd([], [
            view.button(
              view.Ghost,
              view.Medium,
              [
                attribute.attribute("hx-post", "/sign-out"),
                attribute.attribute("hx-target", "closest section"),
                attribute.attribute("hx-swap", "outerHTML"),
                attribute.attribute("hx-disabled-elt", "this"),
                attribute.class(
                  "text-error text-md hover:bg-error-container text-md",
                ),
              ],
              [html.text("sign out"), view.spinner([], icon.Small)],
            ),
          ]),
        ],
      ),
    ],
  )
}

pub fn preference_fallback(msg: String) {
  view.alert(view.Destructive, [], [
    icon.circle_alert([]),
    view.alert_title([], [html.text("Could not load preference")]),
    view.alert_description([], [html.text(msg)]),
  ])
}
