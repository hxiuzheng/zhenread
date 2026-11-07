# 提交与推送身份

本项目维护者为 hxiuzheng。提交和推送钩子运行 `tools/identity.mbtx`，核对当前 GitHub 登录账号、Git 作者和提交者、已有提交历史，以及已配置的推送地址。检查失败时停止操作。

```sh
git config core.hooksPath .githooks
moon run tools/identity.mbtx
```

使用 GitHub 隐私邮箱，不添加其他作者或提交者身份。新克隆仓库需重新启用钩子。钩子是本地检查措施，不替代对推送账号和操作许可的核对。
