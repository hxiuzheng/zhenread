///|
fn read_timeline(path : String, side : String) -> Array[@timeline.Span] {
  let source = read_source(path)
  let filename = path.to_lower()
  let vtt = filename.has_suffix(".vtt")
  if vtt || filename.has_suffix(".srt") {
    let report = @lib.check(source, @lib.chinese_profile(), vtt~)
    if report.findings.any(f => f.severity == "error" && f.rule != "NO_CUES") ||
      (!vtt && report.cues.is_empty()) {
      println(
        "Invalid \{side} subtitle timeline. Run check for source line diagnostics.",
      )
      @sys.exit(2)
    }
    return report.cues.map(cue => {
      track: "subtitles",
      start: cue.start_ms.to_int64(),
      end: cue.end_ms.to_int64(),
    })
  }
  @json.from_json(@json.parse(source, reject_duplicate_keys=true)) catch {
    _ => {
      println(
        "Invalid \{side} JSON. Expected an array of track, start and end records with decimal string endpoints.",
      )
      @sys.exit(2)
      []
    }
  }
}

///|
fn run_coverage(args : Array[String]) -> Unit {
  let report = match args.length() {
    4 => None
    6 if args[4] == "--report" => Some(args[5])
    _ => {
      println("Usage: coverage BASELINE CANDIDATE [--report FILE]")
      @sys.exit(2)
      None
    }
  }
  let baseline = read_timeline(args[2], "baseline")
  let candidate = read_timeline(args[3], "candidate")
  let changes = @timeline.compare_coverage(baseline[:], candidate[:]) catch {
    @timeline.InvalidSpan(side~, index~, reason~) => {
      println("Invalid \{side} interval at position \{index + 1}: \{reason}.")
      @sys.exit(2)
      []
    }
  }
  output_report(Json(changes).stringify(), report)
  if !changes.is_empty() {
    @sys.exit(1)
  }
}
