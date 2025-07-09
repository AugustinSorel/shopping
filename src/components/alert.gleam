import glailwind_merge
import lustre/attribute
import lustre/element
import lustre/element/html
import styles/styles_utils

pub type Variant {
  Default
  Destructive
}

pub fn alert(
  variant: Variant,
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  let base_class = {
    "relative w-full p-4 [&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg+div]:translate-y-[-3px] [&:has(svg)]:pl-11 rounded-lg border"
  }

  let variant_class = case variant {
    Default -> "border-border text-foreground"
    Destructive -> {
      "border-error text-on-error-container [&>svg]:text-on-error-container bg-error-container"
    }
  }

  let attr_class = styles_utils.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, variant_class, attr_class])

  html.div([attribute.role("alert"), attribute.class(class), ..attr], children)
}

pub fn title(
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  html.h5(
    [attribute.class("mb-1 font-medium leading-none tracking-tight"), ..attr],
    children,
  )
}

pub fn description(
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  html.div([attribute.class("[&_p]:leading-relaxed text-sm"), ..attr], children)
}
