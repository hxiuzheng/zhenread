///|
#external
priv type ReportWriteOptions

///|
#module("node:fs")
extern "js" fn write_file_sync(
  path : String,
  content : String,
  options : ReportWriteOptions,
) -> Unit = "writeFileSync"

///|
// Exclusive creation preserves existing files, including when writers race.
extern "js" fn create_report(
  write_file : (String, String, ReportWriteOptions) -> Unit,
  path : String,
  content : String,
) -> Int32 =
  #| (writeFile, path, content) => {
  #|   try {
  #|     writeFile(path, content, { encoding: "utf8", flag: "wx" });
  #|     return 0;
  #|   } catch (error) {
  #|     return error.code === "EEXIST" ? 1 : 2;
  #|   }
  #| }

///|
fn main {
  // The JavaScript target exposes Node's executable and script as argv[0:2].
  // Retain the script slot to match the conventional executable argv layout.
  let args = @env.args()[1:].to_owned()
  if args.length() < 3 || args[1] != "check" {
    println(
      "ZhenRead / 帧读\nUsage: check INPUT [--profile zh|en] [--output text|json|html] [--report FILE] [--strict]\nExit: 0 accepted, 1 findings, 2 usage or I/O error",
    )
    @sys.exit(if args.length() == 2 && args[1] == "--help" { 0 } else { 2 })
  }
  let input = args[2]
  let mut profile = "zh"
  let mut output = "text"
  let mut report_file : String? = None
  let mut strict = false
  let mut i = 3
  while i < args.length() {
    let option = args[i]
    if option == "--strict" {
      strict = true
      i += 1
      continue
    }
    if i + 1 >= args.length() {
      println("Missing option value.")
      @sys.exit(2)
    }
    match option {
      "--profile" => profile = args[i + 1]
      "--output" => output = args[i + 1]
      "--report" => report_file = Some(args[i + 1])
      _ => {
        println("Unknown option.")
        @sys.exit(2)
      }
    }
    i += 2
  }
  if (profile != "zh" && profile != "en") ||
    (output != "text" && output != "json" && output != "html") {
    println("Unsupported profile or output format.")
    @sys.exit(2)
  }
  let lower = input.to_lower()
  if !lower.has_suffix(".srt") && !lower.has_suffix(".vtt") {
    println("Input must be an SRT or VTT file.")
    @sys.exit(2)
  }
  let source = @fs.read_file_to_string(input) catch {
    _ => {
      println("Unable to read subtitle input as UTF-8.")
      @sys.exit(2)
      ""
    }
  }
  let report = @lib.check(
    source,
    if profile == "zh" {
      @lib.chinese_profile()
    } else {
      @lib.english_profile()
    },
    vtt=lower.has_suffix(".vtt"),
  )
  let rendered = match output {
    "json" => report.to_json().stringify()
    "html" => @lib.html_report(report)
    _ => {
      let text = StringBuilder()
      text.write_string(
        "ZhenRead: \{report.cues.length()} cues, \{report.findings.length()} findings\n",
      )
      for f in report.findings {
        text.write_string(
          "\{f.severity} \{f.rule} line \{f.line}: \{f.message}\n",
        )
      }
      text.to_string()
    }
  }
  match report_file {
    Some(path) =>
      match create_report(write_file_sync, path, rendered) {
        0 => ()
        1 => {
          println("Report path already exists. Choose a new path.")
          @sys.exit(2)
        }
        _ => {
          println("Unable to create report.")
          @sys.exit(2)
        }
      }
    None => println(rendered)
  }
  if report.findings.any(f => f.severity == "error" || strict) {
    @sys.exit(1)
  }
}
