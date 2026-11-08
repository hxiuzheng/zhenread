///|
fn revision_text(report : @lib.RevisionReport) -> String {
  let output = StringBuilder()
  for finding in report.baseline_findings {
    output.write_string(
      "baseline line \{finding.line}: \{finding.rule} · \{finding.message}\n",
    )
  }
  for finding in report.candidate_findings {
    output.write_string(
      "candidate line \{finding.line}: \{finding.rule} · \{finding.message}\n",
    )
  }
  if report.is_comparable() {
    output.write_string(
      "ZhenRead: \{report.changes.length()} revision changes\n",
    )
    for change in report.changes {
      let id = Json::string(change.id).stringify()
      output.write_string("\{change.kind} cue \{id}")
      if change.before is Some(cue) {
        output.write_string(" · baseline line \{cue.line}")
      }
      if change.after is Some(cue) {
        output.write_string(" · candidate line \{cue.line}")
      }
      if change.text_changed {
        output.write_string(" · text")
      }
      if change.timing_changed {
        output.write_string(" · timing")
      }
      output.write_string("\n")
    }
  }
  output.to_string()
}

///|
fn run_compare(args : Array[String]) -> Unit {
  let baseline = args[2]
  let candidate = args[3]
  if !baseline.to_lower().has_suffix(".vtt") ||
    !candidate.to_lower().has_suffix(".vtt") {
    println("Revision comparison requires two WebVTT files.")
    @sys.exit(2)
  }
  let mut tolerance = 0
  let mut output = "text"
  let mut report_file : String? = None
  let mut i = 4
  while i < args.length() {
    if i + 1 >= args.length() {
      println("Missing option value.")
      @sys.exit(2)
    }
    let value = args[i + 1]
    match args[i] {
      "--output" => output = value
      "--report" => report_file = Some(value)
      "--tolerance-ms" =>
        tolerance = @string.parse_int(value[:]) catch {
          _ => {
            println("Timing tolerance must be a non-negative integer.")
            @sys.exit(2)
            0
          }
        }
      _ => {
        println("Unknown compare option.")
        @sys.exit(2)
      }
    }
    i += 2
  }
  if tolerance < 0 {
    println("Timing tolerance must be a non-negative integer.")
    @sys.exit(2)
  }
  if output != "text" && output != "json" && output != "html" {
    println("Unsupported revision report format.")
    @sys.exit(2)
  }
  let report = @lib.compare_revisions(
    read_source(baseline),
    read_source(candidate),
    tolerance_ms=tolerance,
  )
  let rendered = match output {
    "json" => report.to_json().stringify()
    "html" => @lib.revision_html_report(report)
    _ => revision_text(report)
  }
  output_report(rendered, report_file)
  if !report.is_comparable() {
    @sys.exit(2)
  }
  if !report.changes.is_empty() {
    @sys.exit(1)
  }
}
