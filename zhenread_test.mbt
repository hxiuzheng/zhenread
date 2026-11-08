///|
test "timestamps reject out of range and malformed input" {
  assert_eq(@zhenread.parse_timestamp("01:02:03,004"), Some(3723004))
  assert_eq(@zhenread.parse_timestamp("02:03.004", vtt=true), Some(123004))
  for
    s in [
      "00:60:00,000", "00:00:60,000", "-1:00:00,000", "00:00:00,00", "00:00:00.000",
      "x",
    ] {
    assert_eq(@zhenread.parse_timestamp(s), None)
  }
}

///|
test "clean Chinese SRT passes with BOM and CRLF" {
  let r = @zhenread.check(
    "\uFEFF1\r\n00:00:01,000 --> 00:00:03,000\r\n欢迎来到帧读\r\n",
    @zhenread.chinese_profile(),
  )
  assert_eq(r.cues.length(), 1)
  assert_eq(r.findings.length(), 0)
  assert_eq(r.cues[0].line, 1)
}

///|
test "malformed block recovers at next blank line" {
  let r = @zhenread.parse(
    "1\ninvalid\n坏字幕\n\n2\n00:00:03,000 --> 00:00:05,000\n正常",
  )
  assert_eq(r.cues.length(), 1)
  assert_eq(r.cues[0].line, 5)
  assert_eq(r.findings[0].rule, "CUE_SYNTAX")
}

///|
test "VTT skips metadata and keeps cue settings out of timestamp" {
  let r = @zhenread.check(
    "WEBVTT\n\nNOTE author\nA note\n\nintro\n00:01.000 --> 00:03.000 align:start\nHello",
    @zhenread.english_profile(),
    vtt=true,
  )
  assert_eq(r.cues.length(), 1)
  assert_eq(r.findings.length(), 0)
  assert_eq(r.cues[0].id, "intro")
}

///|
test "overlap catches a cue inside an earlier long cue" {
  let r = @zhenread.check(
    "1\n00:00:00,000 --> 00:00:10,000\na\n\n2\n00:00:01,000 --> 00:00:02,000\nb\n\n3\n00:00:03,000 --> 00:00:04,000\nc",
    @zhenread.english_profile(),
  )
  assert_eq(r.findings.filter(f => f.rule == "OVERLAP").length(), 2)
}

///|
test "readability rules and reversed duration are diagnosed" {
  let r = @zhenread.check(
    "1\n00:00:02,000 --> 00:00:02,500\n这是一行非常非常长的字幕需要仔细检查是否超过阈值\n第二行\n第三行\n\n2\n00:00:04,000 --> 00:00:03,000\nx",
    @zhenread.chinese_profile(),
  )
  for
    code in [
      "SHORT_DURATION", "READING_SPEED", "LINE_LENGTH", "LINE_COUNT", "TIME_RANGE",
    ] {
    assert_true(r.findings.any(f => f.rule == code))
  }
}

///|
test "Unicode counting ignores tags and whitespace without splitting emoji surrogates" {
  assert_eq(@zhenread.visible_count("<b>你好 😀</b>\nOK"), 5)
}

///|
test "HTML escapes untrusted subtitle content" {
  let r = @zhenread.parse(
    "1\n00:00:01,000 --> 00:00:03,000\n<script>alert('x')</script>",
  )
  let html = @zhenread.html_report(r)
  assert_true(!html.contains("<script>"))
  assert_true(html.contains("&lt;script&gt;"))
  assert_true(html.contains("href=") == false)
}

///|
test "empty inputs and missing VTT header remain visible" {
  assert_eq(@zhenread.parse("").findings[0].rule, "NO_CUES")
  assert_eq(@zhenread.parse("", vtt=true).findings[0].rule, "VTT_HEADER")
}

///|
test "out of order nonintersecting intervals are not overlaps" {
  let r = @zhenread.check(
    "1\n00:00:10,000 --> 00:00:12,000\na\n\n2\n00:00:01,000 --> 00:00:03,000\nb",
    @zhenread.english_profile(),
  )
  assert_true(r.findings.any(f => f.rule == "OUT_OF_ORDER"))
  assert_true(!r.findings.any(f => f.rule == "OVERLAP"))
}

///|
test "adjacent intervals and hour limits" {
  let r = @zhenread.check(
    "1\n00:00:01,000 --> 00:00:02,000\na\n\n2\n00:00:02,000 --> 00:00:03,000\nb",
    @zhenread.english_profile(),
  )
  assert_eq(r.findings.length(), 0)
  assert_eq(@zhenread.parse_timestamp("99:59:59,999"), Some(359999999))
}

///|
test "all HTML delimiters are escaped, not just the first" {
  let r = @zhenread.parse(
    "1\n00:00:01,000 --> 00:00:03,000\n<script>x</script><script>y</script>&&",
  )
  let html = @zhenread.html_report(r)
  assert_true(!html.contains("<script>"))
  assert_true(html.contains("&amp;&amp;"))
}

///|
test "blank cue text is an error" {
  let r = @zhenread.check(
    "1\n00:00:01,000 --> 00:00:03,000\n",
    @zhenread.chinese_profile(),
  )
  assert_eq(r.findings[0].rule, "EMPTY_TEXT")
}

///|
test "reading speed boundary is exact and configurable" {
  let p : @zhenread.Profile = {
    max_cps: 2,
    max_line_chars: 20,
    max_lines: 2,
    min_duration_ms: 800,
  }
  let r = @zhenread.check("1\n00:00:00,000 --> 00:00:01,000\nab", p)
  assert_eq(r.findings.length(), 0)
  let r = @zhenread.check("1\n00:00:00,000 --> 00:00:01,000\nabc", p)
  assert_eq(r.findings[0].rule, "READING_SPEED")
}

///|
test "WebVTT allows long hours up to the supported millisecond bound" {
  assert_eq(
    @zhenread.parse_timestamp("100:00:00.000", vtt=true),
    Some(360000000),
  )
  assert_eq(
    @zhenread.parse_timestamp("596:31:23.647", vtt=true),
    Some(2147483647),
  )
  assert_eq(@zhenread.parse_timestamp("596:31:23.648", vtt=true), None)
  assert_eq(@zhenread.parse_timestamp("999999999999:00:00.000", vtt=true), None)
  assert_eq(@zhenread.parse_timestamp("100:00:00,000"), None)
}

///|
test "WebVTT accepts tab separated settings and preserves source lines" {
  let r = @zhenread.parse(
    "WEBVTT\n\nSTYLE \t\n::cue { color: white }\n\na\n00:01.000\t-->\t00:03.000\talign:start\nHello",
    vtt=true,
  )
  assert_eq(r.findings.length(), 0)
  assert_eq(r.cues.length(), 1)
  assert_eq(r.cues[0].line, 6)
  assert_eq(r.cues[0].end_ms, 3000)
}

///|
test "missing header separator diagnoses and recovers the first cue" {
  let r = @zhenread.parse("WEBVTT\n00:01.000 --> 00:03.000\nHello", vtt=true)
  assert_eq(r.findings[0].rule, "VTT_HEADER")
  assert_eq(r.cues[0].line, 2)
}

///|
test "duplicate timing arrows are diagnosed and the next cue is retained" {
  let r = @zhenread.parse(
    "WEBVTT\n\n00:01.000 --> 00:03.000 --> 00:04.000\nBroken\n\n00:04.000 --> 00:05.000\nHello",
    vtt=true,
  )
  assert_eq(r.findings[0].rule, "CUE_SYNTAX")
  assert_eq(r.cues[0].line, 6)
}

///|
test "unfinished angle markup leaves literal text visible" {
  assert_eq(@zhenread.visible_count("x < y"), 3)
  assert_eq(@zhenread.visible_count("<b>字幕</b> <未结束"), 6)
}
