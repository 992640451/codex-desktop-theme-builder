# 凛晶 / Inori Codex 桌面宠物

[English](README.md) | [简体中文](README.zh-CN.md)

此目录包含可由 Codex Desktop 读取的宠物运行包和可审查的图集资料。

## 运行文件

- `pet.json`：宠物标识、显示名称和图集路径。
- `spritesheet.webp`：1536×1872、8 列×9 行、单格 192×208 的透明动画图集。
- `validation.json`：确定性图集校验与最终视觉 QA 状态。

## 制作资料

该宠物使用 `hatch-pet` 流程，以原创角色主形象作为身份基准，分别生成九种状态，经稳定槽位分帧、透明像素残留与图集尺寸校验，并通过联络表和逐状态动画预览验收。可分发模板不包含中间提示词、生成条带、本机绝对路径或 QA 媒体。

## 安装

在模板根目录运行 `install-inori-pet.cmd`，或手动将 `pet.json`、`spritesheet.webp` 和 `validation.json` 复制到：

```text
%USERPROFILE%\.codex\pets\inori-pet
```

若设置了 `CODEX_HOME`，请改用 `%CODEX_HOME%\pets\inori-pet`。

## 素材说明

宠物图集由 AI 生成，角色是本模板原创的“凛晶 / Inori”：银蓝长发、冰蓝眼、居中切面晶冠和白蓝不对称晶装；设计有意避开既有虚构角色的显著配色与服装组合。

“AI 生成”本身不能保证素材一定具备可版权性或排他性。未来仓库许可证应明确是否覆盖本图集。参见[模板素材说明](../../README.zh-CN.md#素材说明)。
