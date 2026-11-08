# 帧读 ZhenRead

让字幕在发布之前，更好读一点。

帧读使用 MoonBit 实现字幕质量检查和修订回归。内容制作者可以检查单份 SRT 或 WebVTT，也可以比较审定版与待发布版 WebVTT，查看字幕增删、改字和时间漂移。

## 命令行

需要带有 `v0.10.20` 编译器的 MoonBit 工具链和 Node.js。命令行使用 JavaScript 目标，可通过 `moon version --all` 查看编译器版本。

```sh
git clone https://github.com/hxiuzheng/zhenread.git
cd zhenread
moon run cmd/main -- check examples/clean.srt
moon run cmd/main -- check examples/review.vtt --output json
moon run cmd/main -- check examples/review.vtt --output html --report preview.html
```

在浏览器打开生成的 `preview.html`，点击诊断链接定位字幕。命令行按文件扩展名识别 UTF-8 编码的 SRT 和 WebVTT。默认按中文阅读规则检查，使用 `--profile en` 可切换到英文规则。

`--output text|json|html` 选择输出格式，默认是文本。`--report FILE` 在新路径创建报告，否则输出到终端。若目标已存在，请改用新文件名。这样可以保护源字幕和已有报告。

| 退出码 | 含义 |
| --- | --- |
| 0 | 检查通过。默认允许警告 |
| 1 | 有错误，或使用 `--strict` 时有警告 |
| 2 | 参数无效或文件读写失败 |

## 修订回归

两版 WebVTT 的每条字幕需要有显式且唯一的 ID，例如 `definition`。同一条字幕在修订前后保留相同 ID。对比通过 ID 匹配，报告两版的行号、时间和文字；缺少或重复 ID 会在对应版本中报错。

```sh
moon run cmd/main -- compare examples/revision-before.vtt examples/revision-after.vtt --output html --report revision-review.html
```

使用 `--tolerance-ms N` 忽略不超过 N 毫秒的起点和终点偏移，默认值为 0。文字按规范化换行后的正文逐字比较。更换 ID 会被视为删除旧字幕与新增新字幕。支持文本、JSON 和离线并排 HTML，退出码 0 表示无变更、1 表示发现变更、2 表示输入或参数不可用。

## 验证

在仓库根目录运行以下命令。脚本执行静态检查、核心测试、构建、格式校验，并验证命令行的示例输入和退出码。

```sh
moon run tools/verify.mbtx
```

GitHub Actions 在推送和拉取请求中运行同一份验证脚本。

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

WebVTT 文本需设置 `vtt=true`。可使用 `english_profile()`，或构造 `Profile` 自定义阈值。修订回归使用 `compare_revisions` 和 `revision_html_report`。接口清单见 `pkg.generated.mbti`。

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

HTML 报告按播放时间显示字幕。可解析的字幕诊断支持跳转，语法错误会显示源文件行号。报告采用静态页面和 HTML 转义，在本地打开即可。

## 支持范围与人工复核

支持 BOM、LF/CRLF、独立字幕块与常见 SRT/WebVTT 时间格式。WebVTT 支持空格或制表符分隔的定位设置，以及在 32 位毫秒范围内的长时码。工具读取字幕标识符并跳过 NOTE、STYLE 和 REGION 块。定位设置仅用于识别字幕格式，视觉布局需人工复核。当前实现覆盖常见字幕子集。

阅读速度按去掉空白与成对尖括号标签后的 Unicode 标量数量计算。未闭合的尖括号作为正文计数。组合表情、实体引用、复杂排版及字幕与声音的同步仍需人工复核。工具无法确认语义、声音信息描述或完整无障碍合规性。

源文件行号用于定位问题，语法错误块会产生诊断，并在下一个空行后的字幕块继续检查。

## 项目记录

测试覆盖换行规范化、时间码、错误恢复、时间区间、阅读阈值、Unicode 计数和报告转义。样例文本由项目自编，许可证为 Apache-2.0。

- [开发与验证记录](docs/DEVELOPMENT.md)
- [来源与独立贡献](docs/SOURCES.md)
- [申报事实与场景核对](docs/PROPOSAL.md)
- [验收复现与参赛核对](docs/ACCEPTANCE.md)

Mooncakes 包尚未发布；当前请从本仓库运行与评估。
