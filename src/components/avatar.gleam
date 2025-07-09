import gleam/int
import gleam/list
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element/html

fn char_to_int(char: String) -> Int {
  case string.to_utf_codepoints(char) {
    [codepoint] -> string.utf_codepoint_to_int(codepoint)
    _ -> 0
  }
}

fn get_hue_from_string(input: String) -> String {
  let input_as_int = {
    string.to_graphemes(input)
    |> list.fold(0, fn(prev, curr) { prev + char_to_int(curr) })
  }

  let hue = int.bitwise_shift_left(input_as_int, 5)

  int.to_string(hue)
}

pub fn component(value: String) {
  let initial = string.first(value) |> result.unwrap("?")

  html.span(
    [
      attribute.data("initial", initial),
      attribute.class(
        "font-semibold capitalize relative isolate shrink-0 flex size-12 items-center justify-center overflow-hidden rounded-full text-xl after:absolute after:-z-10 after:text-3xl after:blur-lg after:content-[attr(data-initial)]",
      ),
      attribute.styles([
        #(
          "background",
          "light-dark(hsl("
            <> get_hue_from_string(initial)
            <> " 50% 98%), hsl("
            <> get_hue_from_string(initial)
            <> " 50% 6%))",
        ),
        #(
          "color",
          "light-dark(hsl("
            <> get_hue_from_string(initial)
            <> " 50% 40%), hsl("
            <> get_hue_from_string(initial)
            <> " 50% 60%))",
        ),
      ]),
    ],
    [html.text(initial)],
  )
}
