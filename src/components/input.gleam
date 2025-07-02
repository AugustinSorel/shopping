import lustre/attribute
import lustre/element/html

pub fn component(attr: List(attribute.Attribute(msg))) {
  html.input([
    attribute.class(
      "ring-offset-background bg-surface-container-lowest focus-visible:ring-outline border-outline rounded-md border-2 px-5 py-2 focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50",
    ),
    ..attr
  ])
}
