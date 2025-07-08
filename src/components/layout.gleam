import app/web
import components/footer
import lustre/attribute
import lustre/element
import lustre/element/html

pub fn component(
  children: element.Element(msg),
  current_path: String,
  ctx: web.Ctx,
) {
  html.html([attribute.lang("en")], [
    html.head([], [
      html.meta([attribute.charset("utf-8")]),
      html.meta([
        attribute.name("viewport"),
        attribute.content("width=device-width, initial-scale=1"),
      ]),
      html.script(
        [
          attribute.src(
            "https://cdn.jsdelivr.net/npm/htmx.org@2.0.6/dist/htmx.min.js",
          ),
        ],
        "",
      ),
      html.link([
        attribute.href("/static/styles.css"),
        attribute.rel("stylesheet"),
      ]),
      html.meta([
        attribute.name("htmx-config"),
        attribute.content(
          "{\"responseHandling\": [{\"code\":\"...\", \"swap\": true}]}",
        ),
      ]),
      html.title([], "shopping"),
    ]),
    html.body([attribute.class("bg-surface text-on-surface mb-24 p-4")], [
      children,
      footer.component(current_path, ctx),
    ]),
  ])
}
