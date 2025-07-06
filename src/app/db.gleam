import gleam/result
import gleam/time/calendar
import gleam/time/timestamp
import pog

pub fn pog_timestamp_to_timestamp(input: pog.Timestamp) {
  let date = {
    calendar.Date(
      input.date.year,
      calendar.month_from_int(input.date.month)
        |> result.unwrap(calendar.January),
      input.date.day,
    )
  }

  let time = {
    calendar.TimeOfDay(
      input.time.hours,
      input.time.minutes,
      input.time.seconds,
      input.time.microseconds,
    )
  }

  timestamp.from_calendar(date, time, calendar.utc_offset)
}
