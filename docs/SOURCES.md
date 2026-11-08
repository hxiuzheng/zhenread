# 来源与独立贡献

校验库使用 MoonBit 标准库。命令行通过 `moonbitlang/x` 读取字幕并设置退出码，使用 Node.js 的文件接口独占创建报告。项目模板由 `moon new` 创建，许可证为 Apache-2.0。

| 依赖 | 版本 | 用途 | 许可 |
| --- | --- | --- | --- |
| [moonbitlang/x](https://github.com/moonbitlang/x) | 0.5.5 | 读取文件、设置退出码 | Apache-2.0 |
| [moonbitlang/async](https://github.com/moonbitlang/async) | 0.21.3 | 验证脚本的进程调用和临时文件处理 | Apache-2.0 |

帧读为原创实现。Mooncakes 使用 `subtitle`、`webvtt`、`caption`、`srt` 检索发现两项有明显功能交集的项目。以下依据各项目公开说明比较职责。

| 项目 | 已有能力与交集 |
| --- | --- |
| [MaoDingA/moonpost](https://mooncakes.io/docs/MaoDingA/moonpost) · [源码](https://github.com/MaoDingA/moonbitpostqc) | Apache-2.0。支持 SRT、WebVTT、ASS、创作和交付质检、帧网格、双语轨道对齐及自动化输出 |
| [Mr-Houjie/mbt-subtitle](https://mooncakes.io/docs/Mr-Houjie/mbt-subtitle) · [源码](https://github.com/Mr-Houjie/mbt-subtitle) | MIT。支持 SRT/WebVTT、时轴平移缩放、时长与重叠检查，提供命令行和网页界面 |

帧读的单文件格式解析与规则检查存在交集。修订回归将审定版和待发布版按显式 cue ID 关联，记录增删、改字及超过容差的时间漂移，提供两版源行号和离线并排报告。相关项目公开说明用于查重，代码实现参考 WebVTT 规范和本项目既有实现。

相关生态项目：

- [dijdzv/websys.mbt](https://github.com/dijdzv/websys.mbt)
- [moonbit-community/markitdown](https://github.com/moonbit-community/markitdown)
- [AFK-surf/still.fail](https://github.com/AFK-surf/still.fail)

格式参考入口：

- [WebVTT](https://www.w3.org/TR/webvtt1/)
- [SRT 格式背景](https://www.loc.gov/preservation/digital/formats/fdd/fdd000569.shtml)

中英文阈值为初始编辑配置，尚未经过目标用户验证。测试文本为自编内容，未使用真实用户的私人字幕。
