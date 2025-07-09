import glailwind_merge
import lustre/attribute
import lustre/element/html
import styles/styles_utils

pub fn component(attr: List(attribute.Attribute(msg))) {
  let base_class =
    "ring-offset-background bg-surface-container-lowest focus-visible:ring-outline border-outline rounded-md border-2 px-5 py-2 focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50"

  let attr_class = styles_utils.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, attr_class])

  html.input([attribute.class(class), ..attr])
}
