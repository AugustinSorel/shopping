import glailwind_merge
import lustre/attribute
import lustre/element
import lustre/element/html

pub type Variant {
  Default
}

pub type Size {
  Medium
}

pub fn component(
  variant: Variant,
  size: Size,
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  let base_class = {
    "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors gap-2 focus-visible:outline-hidden focus-visible:ring-2 focus:ring-ring focus-visible:ring-offset-2 cursor-pointer"
  }

  let variant_class = case variant {
    Default -> {
      "bg-primary text-on-primary hover:bg-primary/90 font-bold focus-visible:ring-primary"
    }
  }

  let size_class = case size {
    Medium -> "h-10 px-4 py-2 rounded-md"
  }

  let class = glailwind_merge.tw_merge([base_class, variant_class, size_class])

  html.button([attribute.class(class), ..attr], children)
}
