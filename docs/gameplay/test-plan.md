# 玩法测试计划

## 当前覆盖

- `game/test/godot/test_card_combat_core.gd` 覆盖 combo 重置、带 seed 的 deck 确定性，以及卡牌战斗中的伤害/block 结果。
- `game/tools/check-core-rules.sh` 在脚手架仍然轻量时，验证核心规则文件和 Godot 测试入口存在。

## 后续覆盖

- 在项目门禁安装 Godot 后，把 Godot headless runner 接入 CI。
- 增加非法出牌专项测试：mana 不足、手牌索引无效、目标已死亡和空 deck。
- 在实现场景移动前，先添加地牢地图规则测试。
