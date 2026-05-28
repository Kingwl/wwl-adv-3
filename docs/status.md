# 项目状态

## 当前状态

`wwl大冒险3` 是 Godot 2D roguelite 卡牌地牢游戏的最小原型。

## 已实现

- Godot 项目配置。
- 启动场景和启动脚本。
- 基础目录结构。
- 本地 scaffold 检查脚本。
- GitHub Actions scaffold 检查和 Godot headless 测试门禁。
- 核心卡牌战斗第一版：卡牌定义、带 seed 的牌库抽牌、按费用递增的 combo 倍率、战斗者生命/护甲、打牌结算和胜负状态。
- 第 1 关奖励卡池第一版：7 张纯攻击、防御和抽卡卡牌，均使用中文显示名。
- 核心地牢地图第一版：地图 tile、关卡配置、run 状态、fixture 加载、移动阻挡、遭遇触发、拾取物收集和出口解锁。
- 核心 run 控制层第一版：`RunController` 统一玩家命令，供 UI 和流程测试共用移动、自动遭遇、出牌、结束回合、胜利清场和出口请求。
- 敌人 XP 掉落和升级阈值：普通敌人 3 XP、精英 8 XP、首领 14 XP；升级阈值从 10 XP 开始，每级增加 10 XP；战斗胜利事件会返回 XP 和升级事件。
- 固定第 1 关 fixture：16x10 地图、12 个敌人、3 个拾取物、1 个出口，以及击败首领后解锁出口的清关条件。
- 最小 run 场景：启动游戏直接加载第 1 关地图网格，显示玩家、敌人、拾取物、出口、选中格子详情，并支持键盘、鼠标和触摸操作；远处点击只选中格子并显示描边，移动目标是敌人格时自动进入战斗。
- 最小战斗 UI：相邻敌人可创建 `CombatState`，界面聚焦敌方状态和手牌区，并在手牌标题中显示玩家生命、护甲、法力、连击、当前选中项、预览伤害和倍率；卡牌选中态仅上浮，有连锁倍率收益时高亮；支持左右/A/D 切牌、下/S 选中结束回合、空格/回车确认、鼠标点击出牌，费用不足时自动进入下一回合，胜利后回到地图并清除敌人格子。
- Web/UI 中文字体资源：内置 Noto Sans CJK SC，避免 Web 导出环境缺少中文字体导致文字乱码。
- Godot headless 规则测试草案：`game/test/godot/test_card_combat_core.gd`。
- Godot headless 地牢规则测试草案：`game/test/godot/test_dungeon_core.gd`。
- Godot headless 核心流程验收测试：`game/test/godot/test_core_gameplay_flow.gd`。
- Godot headless run 场景 smoke test：`game/test/godot/test_run_scene_smoke.gd`。

## 已验证命令

Godot: 4.6.3 stable.

```bash
cd game
./tools/check-all.sh
./tools/test-godot.sh
```

## 下一步

1. 增加升级/宝箱奖励的 3 选 1 UI。
