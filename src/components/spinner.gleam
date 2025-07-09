import components/icon
import lustre/attribute

pub fn component(attr: List(attribute.Attribute(msg)), size: icon.Size) {
  icon.spinner([attribute.class("htmx-indicator animate-spin"), ..attr], size)
}
