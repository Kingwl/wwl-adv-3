# Agents 指南

## 优先阅读

先阅读 `docs/status.md`，再用 `docs/README.md` 作为文档地图。

## 项目方向

这是一个 Godot 2D roguelite 卡牌地牢游戏脚手架。开发时保持测试驱动：

- 玩法规则放在 `game/scripts/core/`，不要直接嵌进 Godot 场景。
- 优先使用固定 tick 和带 seed 的随机数，保持模拟确定性。
- 场景只负责节点、资源、UI 状态同步和 Godot 特有连接。

## 项目布局

```text
.codex/
└── skills/
docs/
├── screenshots/
game/
├── project.godot
├── scenes/
├── scripts/
│   ├── board/
│   ├── core/
│   └── ui/
├── data/
├── assets/
├── test/
└── tools/
```

## 验证

```bash
cd game
./tools/check-all.sh
```

## 游戏截图留存

每次完成改动后，运行游戏或相关场景，截图记录实际游戏画面的关键环节或改动点，并保存到 `docs/screenshots/`。

- 文件名使用 `YYYYMMDD-HHMM-简短主题.png`，例如 `20260527-1530-combat-ui.png`。
- UI、场景、玩法或规则改动都应尽量截图对应的游戏运行状态，而不是截图 diff 或文档片段。
- 如果某次改动完全不影响当前可运行游戏画面，也至少截图主场景或最接近的可运行场景，作为回归留存。
- 最终回复中说明游戏截图保存路径；如果当前环境无法生成游戏截图，说明原因并记录可复现的运行/验证命令。

## Git 协作

完成里程碑或阶段性交付时，先运行相关验证，再提交 commit 并按需 push。
