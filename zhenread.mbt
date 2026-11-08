///|
#derive(Debug, Eq, ToJson)
pub struct Cue {
  id : String
  line : Int32
  start_ms : Int32
  end_ms : Int32
  text : String
}

///|
pub extend Cue with @debug.Debug::{to_repr}

///|
pub extend Cue with Eq::{equal, not_equal}

///|
pub extend Cue with ToJson::{to_json}

///|
#derive(Debug, Eq, ToJson)
pub struct Finding {
  rule : String
  severity : String
  line : Int32
  cue : String
  message : String
}

///|
pub extend Finding with @debug.Debug::{to_repr}

///|
pub extend Finding with Eq::{equal, not_equal}

///|
pub extend Finding with ToJson::{to_json}

///|
#derive(Debug, ToJson)
pub struct Report {
  cues : Array[Cue]
  findings : Array[Finding]
}

///|
pub extend Report with @debug.Debug::{to_repr}

///|
pub extend Report with ToJson::{to_json}

///|
#derive(Debug)
pub(all) struct Profile {
  max_cps : Int32
  max_line_chars : Int32
  max_lines : Int32
  min_duration_ms : Int32
}

///|
pub extend Profile with @debug.Debug::{to_repr}

///|
/// Editorial defaults, not a certification of accessibility compliance.
pub fn chinese_profile() -> Profile {
  { max_cps: 9, max_line_chars: 20, max_lines: 2, min_duration_ms: 800, }
}

///|
pub fn english_profile() -> Profile {
  { max_cps: 20, max_line_chars: 42, max_lines: 2, min_duration_ms: 800, }
}

///|
fn digits(s : String, width : Int32) -> Int32? {
  if s.length() != width {
    return None
  }
  let mut n = 0
  for c in s.iter() {
    if c < '0' || c > '9' {
      return None
    }
    n = n * 10 + c.to_int() - '0'.to_int()
  }
  Some(n)
}

///|
/// Supports SRT HH:MM:SS,mmm and WebVTT [HH:]MM:SS.mmm.
pub fn parse_timestamp(value : String, vtt~ : Bool = false) -> Int32? {
  let fields = value.split(":").map(s => s.to_owned()).collect()
  let (hours, minutes, seconds) = match fields.length() {
    3 => (fields[0], fields[1], fields[2])
    2 if vtt => ("00", fields[0], fields[1])
    _ => return None
  }
  let delimiter = if vtt { "." } else { "," }
  let parts = seconds.split(delimiter).map(s => s.to_owned()).collect()
  if parts.length() != 2 {
    return None
  }
  guard digits(hours, 2) is Some(h) else { return None }
  guard digits(minutes, 2) is Some(m) else { return None }
  guard digits(parts[0], 2) is Some(s) else { return None }
  guard digits(parts[1], 3) is Some(ms) else { return None }
  if m >= 60 || s >= 60 {
    return None
  }
  Some(((h * 60 + m) * 60 + s) * 1000 + ms)
}

///|
/// Parse independently delimited cue blocks, retaining source line numbers.
pub fn parse(source : String, vtt~ : Bool = false) -> Report {
  let text = source
    .replace_all(old="\r\n", new="\n")
    .replace_all(old="\r", new="\n")
  let text = match text.strip_prefix("\uFEFF") {
    Some(rest) => rest.to_owned()
    None => text
  }
  let lines = text.split("\n").map(s => s.to_owned()).collect()
  let cues : Array[Cue] = []
  let findings : Array[Finding] = []
  if vtt &&
    !(lines[0] == "WEBVTT" ||
    lines[0].has_prefix("WEBVTT ") ||
    lines[0].has_prefix("WEBVTT\t")) {
    findings.push({
      rule: "VTT_HEADER",
      severity: "error",
      line: 1,
      cue: "",
      message: "WebVTT must begin with WEBVTT.",
    })
  }
  let mut i = 0
  while i < lines.length() {
    if lines[i].trim().is_empty() {
      i += 1
      continue
    }
    let begin = i
    while i < lines.length() && !lines[i].trim().is_empty() {
      i += 1
    }
    let first = lines[begin]
    if vtt &&
      (
        (begin == 0 && first.has_prefix("WEBVTT")) ||
        first == "NOTE" ||
        first.has_prefix("NOTE ") ||
        first.has_prefix("NOTE\t") ||
        first == "STYLE" ||
        first == "REGION"
      ) {
      continue
    }
    let timing_index = if first.contains("-->") { begin } else { begin + 1 }
    let id = if timing_index == begin {
      (cues.length() + 1).to_string()
    } else {
      first
    }
    let invalid = fn(message) {
      findings.push({
        rule: "CUE_SYNTAX",
        severity: "error",
        line: begin + 1,
        cue: id,
        message,
      })
    }
    if timing_index >= i {
      invalid("Missing cue timing line.")
      continue
    }
    guard lines[timing_index].split_once("-->") is Some((left, right)) else {
      invalid("Missing timing arrow.")
      continue
    }
    let ending = right.trim().to_owned().split(" ").collect()[0].to_owned()
    guard parse_timestamp(left.trim().to_owned(), vtt~) is Some(start_ms) else {
      invalid("Invalid start timestamp.")
      continue
    }
    guard parse_timestamp(ending, vtt~) is Some(end_ms) else {
      invalid("Invalid end timestamp.")
      continue
    }
    let body = StringBuilder()
    for n = timing_index + 1; n < i; n = n + 1 {
      if n > timing_index + 1 {
        body.write_string("\n")
      }
      body.write_string(lines[n])
    }
    cues.push({ id, line: begin + 1, start_ms, end_ms, text: body.to_string(), })
  }
  if cues.is_empty() {
    findings.push({
      rule: "NO_CUES",
      severity: "error",
      line: 1,
      cue: "",
      message: "No readable cues found.",
    })
  }
  { cues, findings, }
}

///|
/// Count Unicode scalar values, excluding whitespace and inline markup.
/// Complex grapheme clusters may count as several values; thresholds are configurable.
pub fn visible_count(text : String) -> Int32 {
  let mut count = 0
  let mut tag = false
  for c in text.iter() {
    if c == '<' {
      tag = true
    } else if c == '>' && tag {
      tag = false
    } else if !tag && c != ' ' && c != '\t' && c != '\n' && c != '\r' {
      count += 1
    }
  }
  count
}

///|
pub fn check(source : String, profile : Profile, vtt~ : Bool = false) -> Report {
  let report = parse(source, vtt~)
  let findings = report.findings
  let mut previous_start = -1
  for cue in report.cues {
    let add = fn(rule, severity, message) {
      findings.push({ rule, severity, line: cue.line, cue: cue.id, message, })
    }
    let duration = cue.end_ms - cue.start_ms
    if duration <= 0 {
      add("TIME_RANGE", "error", "End must be later than start.")
    } else {
      if duration < profile.min_duration_ms {
        add("SHORT_DURATION", "warning", "Cue is displayed too briefly.")
      }
      if visible_count(cue.text).to_int64() * 1000L >
        profile.max_cps.to_int64() * duration.to_int64() {
        add(
          "READING_SPEED", "warning", "Reading speed exceeds the profile threshold.",
        )
      }
    }
    if cue.start_ms < previous_start {
      add("OUT_OF_ORDER", "error", "Cues are not ordered by start time.")
    }
    previous_start = cue.start_ms
    if visible_count(cue.text) == 0 {
      add("EMPTY_TEXT", "error", "Cue contains no visible text.")
    }
    let body_lines = cue.text.split("\n").collect()
    if body_lines.length() > profile.max_lines {
      add("LINE_COUNT", "warning", "Cue has too many lines.")
    }
    if body_lines.any(line => {
        visible_count(line.to_owned()) > profile.max_line_chars
      }) {
      add("LINE_LENGTH", "warning", "A line exceeds the profile threshold.")
    }
  }
  let ordered = report.cues.filter(c => c.end_ms > c.start_ms)
  ordered.sort_by((a, b) => {
    let order = a.start_ms.compare(b.start_ms)
    if order == 0 {
      a.line.compare(b.line)
    } else {
      order
    }
  })
  let mut latest_end = -1
  for cue in ordered {
    if cue.start_ms < latest_end {
      findings.push({
        rule: "OVERLAP",
        severity: "warning",
        line: cue.line,
        cue: cue.id,
        message: "Cue overlaps another cue; verify intended speakers and placement.",
      })
    }
    latest_end = latest_end.max(cue.end_ms)
  }
  { cues: report.cues, findings, }
}

///|
fn escape_html(s : String) -> String {
  s
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#39;")
}

///|
/// Self-contained, script-free report. No filenames or machine paths are embedded.
pub fn html_report(report : Report) -> String {
  let out = StringBuilder()
  out.write_string(
    "<!doctype html><html lang=\"zh-CN\"><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"><title>帧读 ZhenRead · 字幕质检</title><style>body{margin:0;background:#101c27;color:#e7eef1;font:16px system-ui;line-height:1.6}main{max-width:960px;margin:auto;padding:32px}h1{color:#65dec4}a{color:#65dec4}.card{padding:20px;margin:16px 0;border:1px solid #45606e;border-radius:12px}pre{white-space:pre-wrap;overflow-wrap:anywhere}small{color:#b4c4ce}:target{outline:2px solid #65dec4}</style><main><h1>帧读 ZhenRead</h1><p>字幕阅读质量检查 · 阈值提示不等于无障碍认证</p>",
  )
  out.write_string(
    "<p>\{report.cues.length()} cues · \{report.findings.length()} findings</p><h2>检查结果</h2><ul>",
  )
  for f in report.findings {
    out.write_string(
      "<li><a href=\"#line-\{f.line}\">Line \{f.line}</a> · \{escape_html(f.rule)} · \{escape_html(f.severity)} — \{escape_html(f.message)}</li>",
    )
  }
  out.write_string("</ul><h2>字幕时间顺序</h2>")
  for cue in report.cues {
    out.write_string(
      "<article class=\"card\" id=\"line-\{cue.line}\"><small>\{cue.start_ms}–\{cue.end_ms} ms · Line \{cue.line} · \{escape_html(cue.id)}</small><pre>\{escape_html(cue.text)}</pre></article>",
    )
  }
  out.write_string("</main></html>")
  out.to_string()
}
