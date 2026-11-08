# 来源与独立贡献

校验库仅依赖 MoonBit 标准库。命令行通过 `moonbitlang/x` 读写文件并设置退出码。身份检查脚本使用 `moonbitlang/async` 和 `moonbitlang/x`。项目模板由 `moon new` 创建，许可证为 Apache-2.0。

本项目未从字幕解析仓库复制实现。选题检索发现 MoonBit 生态已有 WebVTT 绑定和字幕处理模块，因此独立贡献集中在面向内容发布的配置化规则、逐行诊断、中文阅读速度检查、离线审阅报告和验证样例。

相关生态项目：

- [dijdzv/websys.mbt](https://github.com/dijdzv/websys.mbt)
- [moonbit-community/markitdown](https://github.com/moonbit-community/markitdown)
- [AFK-surf/still.fail](https://github.com/AFK-surf/still.fail)

格式参考入口：

- [WebVTT](https://www.w3.org/TR/webvtt1/)
- [SRT 格式背景](https://www.loc.gov/preservation/digital/formats/fdd/fdd000569.shtml)

中英文阈值为初始编辑配置，尚未经过目标用户验证。测试文本为自编内容，未使用真实用户的私人字幕。
