# Codex Desktop 主题构建器

[English](README.md) | [简体中文](README.zh-CN.md)

一个用于设计、实现、验证和安全发布 Codex Desktop 自定义主题的可复用 Skill。

本仓库以 `codex-desktop-theme-builder` Skill 为主体。它指导 Codex 通过隔离桌面实例构建可逆主题、识别真实会话状态、保持辅助窗口透明，并在发布前清除私密产物。

## 仓库内容

- 包含实现与发布指南的可复用 Codex Skill。
- 确定性的仓库隐私审计脚本。
- 仅作为完整实现示例提供的原创角色“凛晶 / Inori”冰晶主题模板。
- 不包含真实 Codex 截图、任务记录、日志、凭据或本机用户路径。

## 仓库结构

```text
skills/codex-desktop-theme-builder/
├── SKILL.md
├── agents/openai.yaml
├── references/
├── scripts/audit-theme-repo.ps1
└── assets/templates/inori-frost-theme/
```

仓库主体是 Skill。`assets/templates/` 下的凛晶冰晶包仅演示一种实现，并不是仓库的主要产品。

## 安装 Skill

克隆仓库，然后将 `skills/codex-desktop-theme-builder` 复制到 Codex 主目录下的 `skills` 目录。如果没有设置 `CODEX_HOME`，Codex 通常使用当前用户目录下的 `.codex`。

安装后重启 Codex，可使用类似请求调用 Skill：

```text
使用 $codex-desktop-theme-builder 设计并验证一个可逆的 Codex Desktop 主题。
```

如果使用内置示例，请先把整个 `inori-frost-theme` 模板复制到独立工作目录，再进行修改或运行。不要直接修改已安装 Skill 内的副本。

## 安全模型

该工作流不会修改已签名的 Codex 安装包。主题通过独立用户数据目录启动，并由外部运行时注入器应用。Skill 要求使用语义 DOM 选择器、幂等节点归属、减少动画支持、任务状态验证和明确的宠物窗口隔离。

发布派生主题前运行：

```powershell
& .\skills\codex-desktop-theme-builder\scripts\audit-theme-repo.ps1 -FailOnFinding
& .\skills\codex-desktop-theme-builder\scripts\audit-theme-repo.ps1 -IncludeHistory -FailOnFinding
```

## 隐私与公开发布状态

本仓库使用全新 Git 历史初始化，没有导入真实 UI 截图或旧主题仓库历史。

目前尚未选择开源许可证。在加入许可证之前，默认版权规则继续适用；代码公开可见本身不等于允许他人复用、修改或再分发。

## 许可证与素材边界

仓库包含两类权利状态不同的内容：

- 为本项目编写的 Skill 指令、脚本和主题源码。
- 为本模板原创冰晶角色“凛晶 / Inori”制作的 AI 生成视觉素材。

本仓库中的“Inori”仅指银蓝长发、冰蓝眼、六角晶冠和白蓝晶装的原创角色“凛晶”。当前素材有意避开既有虚构角色的名称、服装、配色组合与其他显著表达。

“AI 生成”只描述图片的制作方式，本身不能保证素材一定具备可版权性、排他性或绝对不存在第三方权利主张。后续软件许可证必须明确是否覆盖视觉素材；在仓库与素材许可证加入之前，代码与图片均适用默认版权规则。

本说明只描述项目预期的权利边界，不构成法律意见。

## 文档语言

面向用户的仓库与模板说明提供英文和简体中文。`SKILL.md` 及 Agent 参考资料保留一套规范英文指令，避免两份 Skill 定义在后续维护中产生行为差异。
