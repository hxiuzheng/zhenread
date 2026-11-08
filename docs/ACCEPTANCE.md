# 验收复现与参赛核对

需要 MoonBit 编译器 v0.10.20 和 Node.js。在仓库根目录执行 `moon run tools/verify.mbtx`，脚本会运行静态检查、构建、格式校验、27 个核心测试、13 个命令行退出码场景及报告文件与修订 HTML 检查。

## 演示步骤

| 操作 | 预期结果 |
| --- | --- |
| `moon run cmd/main -- check examples/clean.srt` | 2 条字幕、0 项诊断，退出码 0 |
| `moon run cmd/main -- check examples/review.vtt --output json` | 3 项警告，分别对应显示过短、阅读过快、时间重叠，退出码 0 |
| `moon run cmd/main -- check examples/review.vtt --strict` | 警告被计入质量门禁，退出码 1 |
| `moon run cmd/main -- check examples/recovery.vtt` | 第 3 行报告多余时间箭头，保留下一条字幕，退出码 1 |
| `moon run cmd/main -- check examples/review.vtt --output html --report preview.html` | 在尚未存在的路径写出 HTML，浏览器可跳转到对应字幕 |
| 重复上一条报告命令 | 已有报告保持原样，提示改用新文件名，退出码 2 |
| `moon run cmd/main -- compare examples/revision-before.vtt examples/revision-after.vtt --output json` | `definition` 有文字和时间变更，`closing` 被删除，`credit` 为新增，退出码 1 |
| `moon run cmd/main -- compare examples/revision-before.vtt examples/revision-after.vtt --output html --report revision-review.html` | 在新路径生成两版并排报告，可按变更 ID 跳转。退出码 1 表示有待复核变更 |

使用 `moon package --list` 检查包内文件，再用 `moon package` 生成本地模块包。包名由模块 `hxiuzheng/zhenread` 和版本号生成。章程 §5.1 阶段三要求申请完成支持的项目发布到 Mooncakes，本地打包之后还需要完成实际发布。

## 章程核对与仓库证据

核对依据为《MoonBit 黑客松大赛章程》正文及两份附录。章程流程中列有 9 月日期，11 月赛的报名、验收及适用安排以本期官方通知为准。[章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd) · [赛事官网](https://moonbitlang.github.io/Hackathon2026/)

| 核对项 | 证据或待办 |
| --- | --- |
| §1–2、§4、附录一：可用、可复用和选题查重 | 库与 CLI 可用于教育、短视频和培训内容。Mooncakes 已有部分功能重合，差异集中在稳定 ID 修订回归和两版复核。参赛者需说明差异及为何独立实现，由组委会判定选题是否合适 |
| §3、§5.2：参赛形式及主要贡献者 | 个人或至多三人团队原则上申报一个项目，团队由代表统一提交。维护方向需参赛者本人为主要贡献者，GitHub 署名可核验，实际贡献由本人确认 |
| §5.1 阶段一、附录二：申报书、场景、提交记录 | [事实与三种场景](PROPOSAL.md)可供作者核对。参赛者须亲写一页 Markdown。新项目要求公开 GitHub 不少于 10 个有效提交，新增提交按实际功能与验证记录审查 |
| §5.1 阶段二、§6：公开可追溯与实质贡献 | [公开仓库](https://github.com/hxiuzheng/zhenread) 默认分支为 `main`。以 `89cb5cc` 比较新增工作，区分历史功能和本轮成果。按真实工作留存 Issue、PR 和更新记录 |
| §5.1 阶段三第 1–3 项：语言、仓库及完整实现 | 主要实现为 MoonBit。解析与单文件质检在 `zhenread.mbt`，两版比较在 `revision.mbt`，报告在 `revision_html.mbt`，命令行在 `cmd/main/` |
| §5.1 阶段三第 4–7 项：README、CI、示例和测试 | [README](../README.md)、示例及本页命令可复现。CI 执行检查、构建和测试。[基线 CI 记录](https://github.com/hxiuzheng/zhenread/actions/runs/42474761827)对应 `89cb5cc`，增强版的本地结果见 [开发记录](DEVELOPMENT.md) |
| §5.1 阶段三第 8 项：Mooncakes | 已验证本地打包，待发布后核验包页面、版本及可安装性 |
| §5.1 阶段三第 9 项、§7、§9：开源与诚信 | 根目录 [Apache-2.0 许可证](../LICENSE)，[来源说明](SOURCES.md)记录依赖、规范及原创样例。验证脚本用临时文件检查防覆盖，发布材料应继续核查数据授权和来源 |
| §2、§6、§9：AI 辅助与可解释 | [开发记录](DEVELOPMENT.md)记录方向、辅助范围、缺陷及复验。作者需亲自说明匹配规则、容差、输入边界和实际贡献 |
| §5–6、§8、§10–11：报名、时间、奖励及展示 | 由参赛者确认本期截止日、方向、资格、报名及验收状态，在入群后使用 GitHub ID。奖励、推荐关系、展示授权与报名同意事项由参赛者依官方通知核对 |
