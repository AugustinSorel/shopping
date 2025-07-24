import client/icon
import client/network
import client/theme
import client/view
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import shared/context

pub fn sync_theme(response) {
  effect.before_paint(fn(dispatch, _) { dispatch(response) })
}

pub fn account_view(on_theme_change) {
  html.main([attribute.class("max-w-app mx-auto space-y-10")], [
    html.button([event.on_click(on_theme_change)], [html.text("click")]),
    html.button([event.on_click(on_theme_change)], [html.text("click 2")]),
  ])
}
