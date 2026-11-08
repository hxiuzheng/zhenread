///|
fn write_revision_cue(out : StringBuilder, title : String, cue : Cue?) -> Unit {
  out.write_string("<section><h3>\{title}</h3>")
  match cue {
    None => out.write_string("<p>无此条字幕</p>")
    Some(cue) =>
      out.write_string(
        "<p>第 \{cue.line} 行 · \{cue.start_ms}–\{cue.end_ms} ms</p><pre>\{escape_html(cue.text)}</pre>",
      )
  }
  out.write_string("</section>")
}

///|
fn revision_change_label(change : RevisionChange) -> String {
  match change.kind {
    "added" => "新增"
    "removed" => "删除"
    _ if change.text_changed && change.timing_changed => "文字与时间变更"
    _ if change.text_changed => "文字变更"
    _ => "时间变更"
  }
}

///|
fn write_revision_findings(
  out : StringBuilder,
  title : String,
  findings : Array[Finding],
) -> Unit {
  if findings.is_empty() {
    return
  }
  out.write_string("<h3>\{title}</h3><ul>")
  for finding in findings {
    out.write_string(
      "<li>第 \{finding.line} 行 · \{escape_html(finding.rule)} · \{escape_html(finding.message)}</li>",
    )
  }
  out.write_string("</ul>")
}

///|
/// Render an offline, side-by-side review of two WebVTT revisions.
pub fn revision_html_report(report : RevisionReport) -> String {
  let out = StringBuilder()
  out.write_string(
    "<!doctype html><html lang=\"zh-CN\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>帧读 · 字幕修订复核</title><style>body{margin:0;background:#101c27;color:#e7eef1;font:16px system-ui;line-height:1.6}main{max-width:960px;margin:auto;padding:24px}a{color:#65dec4}article{margin:20px 0;padding:16px;border:1px solid #45606e;border-radius:12px}.pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}section{padding:12px;background:#192b38}pre{white-space:pre-wrap;overflow-wrap:anywhere}h2{overflow-wrap:anywhere}:target{outline:2px solid #65dec4}@media(max-width:600px){.pair{grid-template-columns:1fr}}</style></head><body><main><h1>字幕修订复核</h1>",
  )
  if !report.is_comparable() {
    out.write_string("<h2>需要修正输入</h2>")
    write_revision_findings(out, "审定版", report.baseline_findings)
    write_revision_findings(out, "待发布版", report.candidate_findings)
  } else if report.changes.is_empty() {
    out.write_string(
      "<p>在选定的时间容差内未发现字幕变更。</p>",
    )
  } else {
    out.write_string(
      "<p>发现 \{report.changes.length()} 项变更</p><nav aria-label=\"变更索引\"><ol>",
    )
    for i, change in report.changes {
      out.write_string(
        "<li><a href=\"#change-\{i + 1}\">\{escape_html(change.id)} · \{revision_change_label(change)}</a></li>",
      )
    }
    out.write_string("</ol></nav>")
    for i, change in report.changes {
      out.write_string(
        "<article id=\"change-\{i + 1}\"><h2>\{escape_html(change.id)} · \{revision_change_label(change)}</h2><div class=\"pair\">",
      )
      write_revision_cue(out, "审定版", change.before)
      write_revision_cue(out, "待发布版", change.after)
      out.write_string("</div></article>")
    }
  }
  out.write_string("</main></body></html>")
  out.to_string()
}
