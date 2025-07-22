import client/icon
import client/network
import client/route
import client/styles
import formal/form
import glailwind_merge
import gleam/bool
import gleam/option
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import shared/context

pub type Variant {
  Default
  Ghost
  Destructive
}

pub type Size {
  Medium
}

pub fn button(
  variant: Variant,
  size: Size,
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  let base_class = {
    "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors gap-2 focus-visible:outline-hidden focus-visible:ring-2 focus:ring-ring focus-visible:ring-offset-2 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
  }

  let variant_class = case variant {
    Default -> {
      "bg-primary text-on-primary hover:bg-primary/90 font-bold focus-visible:ring-primary"
    }
    Ghost -> "hover:bg-accent hover:text-accent-foreground"
    Destructive -> {
      "bg-error text-on-error hover:bg-error/90 font-bold focus-visible:ring-error"
    }
  }

  let size_class = case size {
    Medium -> "h-10 px-4 py-2 rounded-md"
  }

  let attr_class = styles.extract_class(attr)

  let class = {
    glailwind_merge.tw_merge([base_class, variant_class, size_class, attr_class])
  }

  html.button([attribute.class(class), ..attr], children)
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
    Default | Ghost -> "border-border text-foreground"
    Destructive -> {
      "border-error text-on-error-container [&>svg]:text-on-error-container bg-error-container"
    }
  }

  let attr_class = styles.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, variant_class, attr_class])

  html.div([attribute.role("alert"), attribute.class(class), ..attr], children)
}

pub fn alert_title(
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  html.h5(
    [attribute.class("mb-1 font-medium leading-none tracking-tight"), ..attr],
    children,
  )
}

pub fn alert_description(
  attr: List(attribute.Attribute(msg)),
  children: List(element.Element(msg)),
) {
  html.div([attribute.class("[&_p]:leading-relaxed text-sm"), ..attr], children)
}

pub fn checkbox(attr: List(attribute.Attribute(msg))) {
  let base_class = {
    "checked:bg-primary shrink-0 focus-visible:ring-on-surface before:bg-on-primary text-on-surface border-outline flex size-4 cursor-pointer appearance-none items-center justify-center rounded-sm border-2 before:hidden before:size-2.5 before:[clip-path:polygon(14%_44%,0_65%,50%_100%,100%_16%,80%_0%,43%_62%)] checked:border-none checked:before:block focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50"
  }

  let attr_class = styles.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, attr_class])

  html.input([attribute.type_("checkbox"), attribute.class(class), ..attr])
}

pub fn input(attr: List(attribute.Attribute(msg))) {
  let base_class = {
    "ring-offset-background bg-surface-container-lowest focus-visible:ring-outline border-outline rounded-md border-2 px-5 py-2 focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50"
  }

  let attr_class = styles.extract_class(attr)

  let class = glailwind_merge.tw_merge([base_class, attr_class])

  html.input([attribute.class(class), ..attr])
}

pub fn avatar(value: String) {
  let initial = string.first(value) |> result.unwrap("?")

  let hue = styles.hue_from_string(initial)

  html.span(
    [
      attribute.data("initial", initial),
      attribute.class(
        "font-semibold capitalize relative isolate shrink-0 flex size-12 items-center justify-center overflow-hidden rounded-full text-xl after:absolute after:-z-10 after:text-3xl after:blur-lg after:content-[attr(data-initial)]",
      ),
      attribute.styles([
        #(
          "background",
          "light-dark(hsl(" <> hue <> " 50% 98%), hsl(" <> hue <> " 50% 6%))",
        ),
        #(
          "color",
          "light-dark(hsl(" <> hue <> " 50% 40%), hsl(" <> hue <> " 50% 60%))",
        ),
      ]),
    ],
    [html.text(initial)],
  )
}

pub fn footer(
  route route: route.Route,
  session session: option.Option(context.Session),
) {
  use <- bool.guard(when: option.is_none(session), return: element.none())

  html.footer(
    [
      attribute.class(
        "bg-surface-container sm:max-w-app sm:w-app text-on-surface-variant fixed right-0 bottom-0 left-0 flex w-full justify-around sm:left-[max(calc((100%-var(--max-width-app))/2),0rem)] sm:justify-evenly sm:rounded-t-xl",
      ),
    ],
    [
      html.a(
        [
          attribute.class(
            "group flex cursor-pointer flex-col items-center py-4 text-sm",
          ),
          attribute.href(route.to_href(route.Products)),
          attribute.aria_current(
            bool.to_string(route == route.Products)
            |> string.lowercase,
          ),
        ],
        [
          html.span(
            [
              attribute.class(
                "group-hover:bg-surface-container-highest group-aria-[current='true']:bg-secondary-container flex w-full justify-center rounded-full px-6 py-2 transition-colors",
              ),
            ],
            [
              icon.home([
                attribute.class("group-aria-[current='true']:fill-current"),
              ]),
            ],
          ),
          html.span([attribute.class("first-letter:capitalize")], [
            html.text("home"),
          ]),
        ],
      ),
      html.a(
        [
          attribute.class(
            "group flex cursor-pointer flex-col items-center py-4 text-sm",
          ),
          attribute.href(
            route.to_href(route.CreateProduct(
              form: form.new(),
              state: network.Idle,
            )),
          ),
          attribute.aria_current(
            bool.to_string(case route {
              route.CreateProduct(..) -> True
              _ -> False
            })
            |> string.lowercase,
          ),
        ],
        [
          html.span(
            [
              attribute.class(
                "group-hover:bg-surface-container-highest group-aria-[current='true']:bg-secondary-container flex w-full justify-center rounded-full px-6 py-2 transition-colors",
              ),
            ],
            [
              icon.circle_plus([
                attribute.class(
                  "group-aria-[current='true']:[&_path]:stroke-surface-container group-aria-[current='true']:fill-current",
                ),
              ]),
            ],
          ),
          html.span([attribute.class("first-letter:capitalize")], [
            html.text("add"),
          ]),
        ],
      ),
      html.a(
        [
          attribute.class(
            "group flex cursor-pointer flex-col items-center py-4 text-sm",
          ),
          attribute.href(route.to_href(route.Account)),
          attribute.aria_current(
            bool.to_string(route == route.Account)
            |> string.lowercase,
          ),
        ],
        [
          html.span(
            [
              attribute.class(
                "group-hover:bg-surface-container-highest group-aria-[current='true']:bg-secondary-container flex w-full justify-center rounded-full px-6 py-2 transition-colors",
              ),
            ],
            [
              icon.user([
                attribute.class("group-aria-[current='true']:fill-current"),
              ]),
            ],
          ),
          html.span([attribute.class("first-letter:capitalize")], [
            html.text("account"),
          ]),
        ],
      ),
    ],
  )
}

pub fn spinner(attr: List(attribute.Attribute(msg)), size: icon.Size) {
  icon.spinner([attribute.class("animate-spin"), ..attr], size)
}
