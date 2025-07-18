import glailwind_merge
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/element/svg
import styles

pub type Size {
  Small
  Medium
}

fn icon(
  size: Size,
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  let base_class = {
    "fill-none stroke-current group-aria-[current='true']:fill-current"
  }

  let size_attrs = case size {
    Small -> [attribute.height(16), attribute.width(16)]
    Medium -> [attribute.height(24), attribute.width(24)]
  }

  let attr_class = styles.extract_class(attr)

  let class = glailwind_merge.tw_merge([attr_class, base_class])

  html.svg(
    [
      attribute.attribute("viewbox", "0 0 24 24"),
      attribute.attribute("stroke-linecap", "round"),
      attribute.attribute("stroke-linejoin", "round"),
      attribute.class(class),
      ..list.append(attr, size_attrs)
    ],
    children,
  )
}

pub fn home(attr: List(attribute.Attribute(msg))) {
  icon(Medium, attr, [
    svg.path([
      attribute.attribute(
        "d",
        "M1 22V9.76a2 2 0 0 1 .851-1.636l9.575-6.72a1 1 0 0 1 1.149 0l9.574 6.72A2 2 0 0 1 23 9.76V22a1 1 0 0 1-1 1h-5.333a1 1 0 0 1-1-1v-5.674a1 1 0 0 0-1-1H9.333a1 1 0 0 0-1 1V22a1 1 0 0 1-1 1H2a1 1 0 0 1-1-1z",
      ),
    ]),
  ])
}

pub fn circle_plus(attr: List(attribute.Attribute(msg))) {
  icon(Medium, attr, [
    svg.circle([
      attribute.attribute("cx", "12"),
      attribute.attribute("cy", "12"),
      attribute.attribute("r", "10"),
    ]),
    svg.path([attribute.attribute("d", "M8 12h8")]),
    svg.path([attribute.attribute("d", "M12 8v8")]),
  ])
}

pub fn user(attr: List(attribute.Attribute(msg))) {
  icon(Medium, attr, [
    svg.path([
      attribute.attribute("d", "M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"),
    ]),
    svg.circle([
      attribute.attribute("cx", "12"),
      attribute.attribute("cy", "7"),
      attribute.attribute("r", "4"),
    ]),
  ])
}

pub fn circle_alert(attr: List(attribute.Attribute(msg))) {
  icon(Medium, attr, [
    svg.circle([
      attribute.attribute("cx", "12"),
      attribute.attribute("cy", "12"),
      attribute.attribute("r", "10"),
    ]),
    svg.line([
      attribute.attribute("x1", "12"),
      attribute.attribute("x2", "12"),
      attribute.attribute("y1", "8"),
      attribute.attribute("y2", "12"),
    ]),
    svg.line([
      attribute.attribute("x1", "12"),
      attribute.attribute("x2", "12"),
      attribute.attribute("y1", "16"),
      attribute.attribute("y2", "16"),
    ]),
  ])
}

pub fn spinner(attr: List(attribute.Attribute(msg)), size: Size) {
  icon(size, attr, [
    svg.path([attribute.attribute("d", "M12 2v4")]),
    svg.path([attribute.attribute("d", "m16.2 7.8 2.9-2.9")]),
    svg.path([attribute.attribute("d", "M18 12h4")]),
    svg.path([attribute.attribute("d", "M12 18v4")]),
    svg.path([attribute.attribute("d", "m4.9 19.1 2.9-2.9")]),
    svg.path([attribute.attribute("d", "M2 12h4")]),
    svg.path([attribute.attribute("d", "m4.9 4.9 2.9 2.9")]),
  ])
}
