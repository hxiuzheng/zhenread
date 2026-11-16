///|
test "adjacent fragments and reordered inputs have equivalent coverage" {
  let baseline : Array[@timeline.Span] = [{ track: "cut", start: 0L, end: 8L, }]
  let candidate : Array[@timeline.Span] = [
    { track: "cut", start: 4L, end: 8L, },
    { track: "cut", start: 0L, end: 4L, },
  ]
  assert_true(@timeline.compare_coverage(baseline[:], candidate[:]).is_empty())
}

///|
test "tracks remain independent and ranges are maximal" {
  let baseline : Array[@timeline.Span] = [{ track: "b", start: 0L, end: 8L, }]
  let candidate : Array[@timeline.Span] = [
    { track: "b", start: 0L, end: 4L, },
    { track: "a", start: 1L, end: 2L, },
    { track: "b", start: 2L, end: 6L, },
  ]
  let result = @timeline.compare_coverage(baseline[:], candidate[:])
  assert_eq(result.length(), 3)
  assert_eq(result.map(x => (x.track, x.start, x.end, x.before, x.after)), [
    ("a", 1L, 2L, 0L, 1L),
    ("b", 2L, 4L, 1L, 2L),
    ("b", 6L, 8L, 1L, 0L),
  ])
}

///|
test "adjacent equal differences merge across shared boundaries" {
  let fragments : Array[@timeline.Span] = [
    { track: "a", start: -5L, end: 0L, },
    { track: "a", start: 0L, end: 5L, },
  ]
  let result = @timeline.compare_coverage([], fragments[:])
  assert_eq(result.length(), 1)
  assert_eq((result[0].start, result[0].end), (-5L, 5L))
}

///|
test "the sweep does not subtract extreme coordinates" {
  let spans : Array[@timeline.Span] = [
    { track: "x", start: -9223372036854775807L, end: 9223372036854775807L, },
  ]
  let result = @timeline.compare_coverage(spans[:], [])
  assert_eq(
    (result[0].start, result[0].end),
    (-9223372036854775807L, 9223372036854775807L),
  )
}

///|
test "invalid spans name the side and zero-based input index" {
  let invalid : Array[@timeline.Span] = [{ track: "x", start: 2L, end: 2L, }]
  let rejected = try {
    ignore(@timeline.compare_coverage([], invalid[:]))
    false
  } catch {
    @timeline.InvalidSpan(side="candidate", index=0, ..) => true
    _ => false
  }
  assert_true(rejected)
}

///|
test "sweep agrees with a pointwise oracle over many overlapping datasets" {
  for seed in 0..<96 {
    let before : Array[@timeline.Span] = []
    let after : Array[@timeline.Span] = []
    for i in 0..<8 {
      let track = if (i + seed) % 2 == 0 { "a" } else { "b" }
      let a = ((seed * 11 + i * i * 7) % 21 - 10).to_int64()
      let b = ((seed * 13 + i * 17) % 21 - 10).to_int64()
      before.push({ track, start: a, end: a + (i % 5 + 1).to_int64(), })
      after.push({ track, start: b, end: b + ((seed + i) % 5 + 1).to_int64(), })
    }
    let result = @timeline.compare_coverage(before[:], after[:])
    for track in ["a", "b"] {
      for i in -11..<16 {
        let point = i.to_int64()
        let a = before
          .filter(x => x.track == track && x.start <= point && point < x.end)
          .length()
          .to_int64()
        let b = after
          .filter(x => x.track == track && x.start <= point && point < x.end)
          .length()
          .to_int64()
        let actual = result.filter(x => {
          x.track == track && x.start <= point && point < x.end
        })
        if a == b {
          assert_true(actual.is_empty())
        } else {
          assert_eq(actual.length(), 1)
          assert_eq((actual[0].before, actual[0].after), (a, b))
        }
      }
    }
  }
}
