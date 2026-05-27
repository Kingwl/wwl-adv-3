# 项目状态

## 当前状态

`wwl大冒险3` 是 Godot 2D roguelite 卡牌地牢游戏的最小原型。

## 已实现

- Godot 项目配置。
- 启动场景和启动脚本。
- 基础目录结构。
- 本地 scaffold 检查脚本。
- GitHub Actions scaffold 检查。
- 核心卡牌战斗第一版：卡牌定义、带 seed 的牌库抽牌、按费用递增的 combo 倍率、战斗者生命/护甲、打牌结算和胜负状态。
- Godot headless 规则测试草案：`game/test/godot/test_card_combat_core.gd`。

## 已验证命令

Godot: 4.6.3 stable.

```bash
cd game
./tools/check-all.sh
godot --headless --path . -s res://test/godot/test_card_combat_core.gd
```

## 下一步

1. 将 Godot headless 测试接入 CI 门禁。
2. 增加 2D 地牢地图和遭遇节点核心规则。
3. 引入最小可玩场景，把核心战斗状态接到 UI。
