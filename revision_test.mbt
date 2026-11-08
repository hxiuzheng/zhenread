///|
test "revision comparison pairs IDs across positions and captures both edits" {
  let baseline = "WEBVTT\n\nold\n00:01.000 --> 00:02.000\n移除\n\nshared\n00:03.000 --> 00:04.000\n旧字\n\nsame\n00:05.000 --> 00:06.000\n相同"
  let candidate = "WEBVTT\n\nshared\n00:03.200 --> 00:04.300\n新字\n\nsame\n00:05.000 --> 00:06.000\n相同\n\nnew\n00:07.000 --> 00:08.000\n新增"
  let result = @zhenread.compare_revisions(baseline, candidate)
  assert_true(result.is_comparable())
  assert_eq(result.changes.map(c => c.kind), ["removed", "modified", "added"])
  let change = result.changes[1]
  assert_eq(change.id, "shared")
  assert_true(change.text_changed)
  assert_true(change.timing_changed)
  assert_eq(change.before.map(c => c.line), Some(7))
  assert_eq(change.after.map(c => c.line), Some(3))
}

///|
test "revision timing tolerance is inclusive" {
  let baseline = "WEBVTT\n\nchapter\n00:01.000 --> 00:02.000\n开始"
  let candidate = "WEBVTT\n\nchapter\n00:01.050 --> 00:02.050\n开始"
  assert_eq(
    @zhenread.compare_revisions(baseline, candidate, tolerance_ms=50).changes.length(),
    0,
  )
  assert_eq(
    @zhenread.compare_revisions(baseline, candidate, tolerance_ms=49).changes.length(),
    1,
  )
}

///|
test "revision rejects ambiguous and missing IDs on the corresponding side" {
  let baseline = "WEBVTT\n\nx\n00:01.000 --> 00:02.000\n一\n\nx\n00:03.000 --> 00:04.000\n二"
  let candidate = "WEBVTT\n\n00:03.000 --> 00:04.000\n无标识"
  let result = @zhenread.compare_revisions(baseline, candidate)
  assert_true(!result.is_comparable())
  assert_eq(result.changes.length(), 0)
  assert_eq(result.baseline_findings[0].rule, "REVISION_DUPLICATE_ID")
  assert_eq(result.baseline_findings[0].line, 7)
  assert_eq(result.candidate_findings[0].rule, "REVISION_ID_REQUIRED")
}

///|
test "valid empty revisions detect complete removal or first additions" {
  let empty = "WEBVTT\n\n"
  let one = "WEBVTT\n\nitem\n00:01.000 --> 00:02.000\n字幕"
  assert_eq(@zhenread.compare_revisions(one, empty).changes[0].kind, "removed")
  assert_eq(@zhenread.compare_revisions(empty, one).changes[0].kind, "added")
  assert_true(!@zhenread.compare_revisions(one, "").is_comparable())
}
