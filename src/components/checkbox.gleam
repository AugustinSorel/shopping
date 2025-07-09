import glailwind_merge
import lustre/attribute
import lustre/element/html
import styles/styles_utils

pub fn component(attr: List(attribute.Attribute(msg))) {
  let base_class =
    "checked:bg-primary shrink-0 focus-visible:ring-on-surface before:bg-on-primary text-on-surface border-outline flex size-4 cursor-pointer appearance-none items-center justify-center rounded-sm border-2 before:hidden before:size-2.5 before:[clip-path:polygon(14%_44%,0_65%,50%_100%,100%_16%,80%_0%,43%_62%)] checked:border-none checked:before:block focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50"

  let attr_class = styles_utils.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, attr_class])

  html.input([attribute.type_("checkbox"), attribute.class(class), ..attr])
}
