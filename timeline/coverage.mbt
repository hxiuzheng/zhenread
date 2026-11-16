///|
/// An interval on a named track. Both versions must use the same unit and origin.
#derive(FromJson, ToJson)
pub(all) struct Span {
  track : String
  start : Int64
  end : Int64
}

///|
pub extend Span with @json.FromJson::{from_json}

///|
pub extend Span with ToJson::{to_json}

///|
/// Maximal half-open range with the same pair of unequal coverage counts.
#derive(Debug, Eq, ToJson)
pub struct CoverageChange {
  track : String
  start : Int64
  end : Int64
  before : Int64
  after : Int64
}

///|
pub extend CoverageChange with @debug.Debug::{to_repr}

///|
pub extend CoverageChange with Eq::{equal, not_equal}

///|
pub extend CoverageChange with ToJson::{to_json}

///|
#derive(Debug)
pub suberror CoverageError {
  InvalidSpan(side~ : String, index~ : Int32, reason~ : String)
}

///|
pub extend CoverageError with @debug.Debug::{to_repr}

///|
priv struct Boundary {
  track : String
  at : Int64
  before : Int64
  after : Int64
}

///|
fn add_boundaries(
  events : Array[Boundary],
  spans : ArrayView[Span],
  side : String,
  baseline : Bool,
) -> Unit raise CoverageError {
  for index, span in spans {
    if span.track.trim().is_empty() {
      raise InvalidSpan(side~, index~, reason="track name must not be blank")
    }
    if span.start >= span.end {
      raise InvalidSpan(side~, index~, reason="start must be smaller than end")
    }
    let before = if baseline { 1L } else { 0L }
    let after = if baseline { 0L } else { 1L }
    events.push({ track: span.track, at: span.start, before, after, })
    events.push({
      track: span.track,
      at: span.end,
      before: -before,
      after: -after,
    })
  }
}

///|
fn append_change(
  changes : Array[CoverageChange],
  current : CoverageChange,
) -> Unit {
  let last = changes.length() - 1
  if last >= 0 {
    let previous = changes[last]
    if previous.track == current.track &&
      previous.end == current.start &&
      previous.before == current.before &&
      previous.after == current.after {
      changes[last] = { ..previous, end: current.end, }
      return
    }
  }
  changes.push(current)
}

///|
/// Compare per-track coverage counts. Sorts boundaries in O(n log n) time, then
/// scans once. Equal counts are omitted, and results are ordered by track and time.
/// Input intervals have half-open semantics. Touching boundaries are aggregated.
///
/// ```mbt check
/// test {
///   let baseline : Array[@timeline.Span] = [
///     { track: "edit", start: 0L, end: 8L, },
///   ]
///   let candidate : Array[@timeline.Span] = [
///     { track: "edit", start: 0L, end: 6L, },
///   ]
///   let changes = @timeline.compare_coverage(baseline[:], candidate[:])
///   assert_eq(changes[0].start, 6L)
///   assert_eq(changes[0].after, 0L)
/// }
/// ```
pub fn compare_coverage(
  baseline : ArrayView[Span],
  candidate : ArrayView[Span],
) -> Array[CoverageChange] raise CoverageError {
  let events : Array[Boundary] = []
  add_boundaries(events, baseline, "baseline", true)
  add_boundaries(events, candidate, "candidate", false)
  events.sort_by((a, b) => {
    let order = a.track.compare(b.track)
    if order == 0 {
      a.at.compare(b.at)
    } else {
      order
    }
  })
  let changes = []
  let mut i = 0
  while i < events.length() {
    let track = events[i].track
    let mut previous_at = events[i].at
    let mut before = 0L
    let mut after = 0L
    while i < events.length() && events[i].track == track {
      let at = events[i].at
      if previous_at < at && before != after {
        append_change(changes, {
          track,
          start: previous_at,
          end: at,
          before,
          after,
        })
      }
      while i < events.length() &&
            events[i].track == track &&
            events[i].at == at {
        before += events[i].before
        after += events[i].after
        i += 1
      }
      previous_at = at
    }
  }
  changes
}
