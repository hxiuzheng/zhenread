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
fn read_source(path : String) -> String {
  let bytes = @fs.read_file_to_bytes(path) catch {
    _ => {
      println("Unable to read subtitle input.")
      @sys.exit(2)
      b""
    }
  }
  @utf8.decode(bytes[:]) catch {
    _ => {
      println("Subtitle input must be valid UTF-8.")
      @sys.exit(2)
      ""
    }
  }
}

///|
fn output_report(rendered : String, report_file : String?) -> Unit {
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
}

///|
fn run_check(args : Array[String]) -> Unit {
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
  let source = read_source(input)
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
  output_report(rendered, report_file)
  if report.findings.any(f => f.severity == "error" || strict) {
    @sys.exit(1)
  }
}

///|
fn main {
  // Retain Node's script slot to match the conventional executable argv layout.
  let args = @env.args()[1:].to_owned()
  if args.length() >= 3 && args[1] == "check" {
    run_check(args)
  } else if args.length() >= 4 && args[1] == "compare" {
    run_compare(args)
  } else {
    println(
      "ZhenRead / 帧读\nUsage: check INPUT [--profile zh|en] [--output text|json|html] [--report FILE] [--strict]\n       compare BASELINE.vtt CANDIDATE.vtt [--tolerance-ms N] [--output text|json] [--report FILE]\nExit: 0 accepted, 1 findings or changes, 2 invalid input or usage/I/O error",
    )
    @sys.exit(if args.length() == 2 && args[1] == "--help" { 0 } else { 2 })
  }
}
