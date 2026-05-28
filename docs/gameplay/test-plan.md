# 玩法测试计划

## 当前覆盖

- `game/test/godot/test_card_combat_core.gd` 覆盖 combo 重置、带 seed 的 deck 确定性、卡牌战斗中的伤害/block 结果，以及第 1 关奖励卡池的数量、唯一 id、中文显示名和攻击/防御/抽卡三类纯效果约束。
- `game/test/godot/test_dungeon_core.gd` 覆盖地图 fixture 确定性、移动阻挡、遭遇触发、拾取物收集、首领击败出口解锁、非首领击败数不解锁第 1 关出口、run 初始化、XP 阈值曲线，以及固定第 1 关内容预算。
- `game/test/godot/test_core_gameplay_flow.gd` 覆盖一条核心玩法验收流程：启动第 1 关、用寻路移动到敌人格自动开始遭遇和卡牌战斗、击败首领、获得 XP 和升级事件、收集一个可达物品、解锁出口并请求过关。测试只断言玩家意图和核心结果，不绑定 UI 节点、具体坐标或具体卡牌顺序。
- `game/test/godot/test_run_scene_smoke.gd` 覆盖 run 场景能加载第 1 关地图、创建 160 个地图格、绑定基础 UI 节点、远处点击只选中不移动、触摸地图格移动并进入战斗、战斗手牌键盘选择和确认出牌、鼠标 hover 同步选择、进入战斗 UI，以及胜利后回到地图清除敌人并显示 XP。
- `game/tools/check-core-rules.sh` 在脚手架仍然轻量时，验证核心规则文件和 Godot 测试入口存在。

## 后续覆盖

- 增加非法出牌专项测试：mana 不足、手牌索引无效、目标已死亡和空 deck。
- 添加战斗 UI 交互测试，覆盖出牌、结束回合、玩家失败和胜利清场。
