# 帧读 ZhenRead

让字幕在发布之前，更好读一点。

帧读是面向课程、短视频和培训内容的字幕质量检查工具，使用 MoonBit 实现。输入 SRT 或 WebVTT 字幕，输出带规则编号、严重程度和源文件行号的诊断，帮助内容制作者在发布前复核字幕。

## 命令行

需要 MoonBit 工具链和 Node.js。命令行使用 JavaScript 目标。

```sh
git clone https://github.com/hxiuzheng/zhenread.git
cd zhenread
moon run cmd/main -- check examples/clean.srt
moon run cmd/main -- check examples/review.vtt --output json
moon run cmd/main -- check examples/review.vtt --output html --report preview.html
```

在浏览器打开生成的 `preview.html`，点击诊断链接定位字幕。命令行按文件扩展名识别 UTF-8 编码的 SRT 和 WebVTT。默认按中文阅读规则检查，使用 `--profile en` 可切换到英文规则。

`--output text|json|html` 选择输出格式，默认是文本。`--report FILE` 将报告写入指定文件，否则输出到终端。

| 退出码 | 含义 |
| --- | --- |
| 0 | 检查通过。默认允许警告 |
| 1 | 有错误，或使用 `--strict` 时有警告 |
| 2 | 参数无效或文件读写失败 |

## 验证

```sh
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
moon fmt --check
```

## 校验接口

在库中通过 `check` 校验字幕，通过 `html_report` 生成离线 HTML，或用 `Report.to_json()` 导出结构化数据。以下示例可放入本项目的黑盒测试文件运行：

```mbt
test "check a Chinese cue" {
  let source = "1\n00:00:01,000 --> 00:00:03,000\n欢迎来到帧读"
  let report = @zhenread.check(source, @zhenread.chinese_profile())
  assert_eq(report.cues.length(), 1)
  assert_eq(report.findings.length(), 0)
}
```

WebVTT 文本需设置 `vtt=true`。可使用 `english_profile()`，或构造 `Profile` 自定义阈值。接口清单见 `pkg.generated.mbti`。

## 检查内容

| 规则 | 含义 |
| --- | --- |
| CUE_SYNTAX / VTT_HEADER | 时间码、字幕结构或 WebVTT 文件头异常 |
| NO_CUES / EMPTY_TEXT | 无可读字幕或内容为空 |
| TIME_RANGE / OUT_OF_ORDER | 起止时间异常或字幕乱序 |
| OVERLAP | 字幕时间区间重叠，需核对多人说话和字幕位置 |
| SHORT_DURATION | 显示时间过短 |
| READING_SPEED | 阅读速度超过所选阈值 |
| LINE_LENGTH / LINE_COUNT | 单行过长或行数过多 |

中文默认配置：每秒 9 个可见字符、每行 20 字、最多 2 行、最短显示 800 毫秒。英文默认配置：每秒 20 字符、每行 42 字符，其余相同。这些是待使用者按内容调整的编辑建议，不代表平台规范或无障碍认证。

HTML 报告包含字幕时间顺序和诊断跳转，采用静态页面及 HTML 转义。校验库不包含网络上传功能。

## 支持范围与人工复核

支持 BOM、LF/CRLF、独立字幕块与常见 SRT/WebVTT 时间格式。WebVTT 可读取字幕标识符和结束时间后的设置，跳过 NOTE/STYLE/REGION 元数据块；设置不参与视觉布局分析。当前仅实现常见字幕子集。

阅读速度按去掉空白与尖括号标签后的 Unicode 标量数量计算；组合表情、实体引用、复杂排版及字幕与声音的同步仍需人工复核。工具无法确认语义、声音信息描述或完整无障碍合规性。

源文件行号用于定位问题，语法错误块会产生诊断，并在下一个空行后的字幕块继续检查。

## 项目记录

测试覆盖换行规范化、时间码、错误恢复、时间区间、阅读阈值、Unicode 计数和报告转义。样例文本由项目自编，许可证为 Apache-2.0。

- [开发与验证记录](docs/DEVELOPMENT.md)
- [来源与独立贡献](docs/SOURCES.md)

Mooncakes 包尚未发布；当前请从本仓库运行与评估。
