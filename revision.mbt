///|
#derive(Debug, ToJson)
pub struct RevisionChange {
  kind : String
  id : String
  before : Cue?
  after : Cue?
  text_changed : Bool
  timing_changed : Bool
}

///|
pub extend RevisionChange with ToJson::{to_json}

///|
pub extend RevisionChange with @debug.Debug::{to_repr}

///|
#derive(Debug, ToJson)
pub struct RevisionReport {
  baseline_findings : Array[Finding]
  candidate_findings : Array[Finding]
  changes : Array[RevisionChange]
}

///|
pub extend RevisionReport with ToJson::{to_json}

///|
pub extend RevisionReport with @debug.Debug::{to_repr}

///|
pub fn RevisionReport::is_comparable(self : RevisionReport) -> Bool {
  self.baseline_findings.is_empty() && self.candidate_findings.is_empty()
}

///|
fn index_revision(report : Report) -> Map[String, Cue] {
  let cues : Map[String, Cue] = Map([])
  for cue in report.cues {
    if cues.contains(cue.id) {
      report.findings.push({
        rule: "REVISION_DUPLICATE_ID",
        severity: "error",
        line: cue.line,
        cue: cue.id,
        message: "Each cue identifier must be unique within a revision.",
      })
    } else {
      cues.set(cue.id, cue)
    }
    if cue.end_ms <= cue.start_ms {
      report.findings.push({
        rule: "TIME_RANGE",
        severity: "error",
        line: cue.line,
        cue: cue.id,
        message: "End must be later than start.",
      })
    }
  }
  cues
}

///|
/// Compare WebVTT revisions by explicit, unique cue identifiers.
/// An invalid input yields side-specific findings and no changes.
/// Timing tolerance is inclusive and negative values are treated as zero.
pub fn compare_revisions(
  baseline : String,
  candidate : String,
  tolerance_ms~ : Int32 = 0,
) -> RevisionReport {
  let before = parse_cues(baseline, vtt=true, require_ids=true)
  let after = parse_cues(candidate, vtt=true, require_ids=true)
  let before_index = index_revision(before)
  let after_index = index_revision(after)
  let changes : Array[RevisionChange] = []
  let report = {
    baseline_findings: before.findings,
    candidate_findings: after.findings,
    changes,
  }
  if !report.is_comparable() {
    return report
  }
  let tolerance = tolerance_ms.max(0)
  for old in before.cues {
    match after_index.get(old.id) {
      None =>
        changes.push({
          kind: "removed",
          id: old.id,
          before: Some(old),
          after: None,
          text_changed: false,
          timing_changed: false,
        })
      Some(current) => {
        let text_changed = old.text != current.text
        let timing_changed = (old.start_ms - current.start_ms).abs() > tolerance ||
          (old.end_ms - current.end_ms).abs() > tolerance
        if text_changed || timing_changed {
          changes.push({
            kind: "modified",
            id: old.id,
            before: Some(old),
            after: Some(current),
            text_changed,
            timing_changed,
          })
        }
      }
    }
  }
  for current in after.cues {
    if !before_index.contains(current.id) {
      changes.push({
        kind: "added",
        id: current.id,
        before: None,
        after: Some(current),
        text_changed: false,
        timing_changed: false,
      })
    }
  }
  report
}
