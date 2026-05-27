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

## Git 协作

完成 milestone 或阶段性交付时，先运行相关验证，再提交 commit 并按需 push。
