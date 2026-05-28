extends SceneTree

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const CombatState = preload("res://scripts/core/combat/combat_state.gd")
const DungeonMapState = preload("res://scripts/core/dungeon/dungeon_map_state.gd")
const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const RunController = preload("res://scripts/core/run/run_controller.gd")
const StageFixtureCatalog = preload("res://scripts/core/dungeon/stage_fixture_catalog.gd")

# 流程测试不验证数值平衡，使用较高生命避免敌人/卡牌调参造成误报。
const FLOW_HEALTH_BUDGET := 999
const MAX_ENCOUNTER_STEPS := 80
const INVALID_POSITION := Vector2i(-9999, -9999)


func _init() -> void:
	var failed := false
	failed = not _test_victory_grants_xp_and_level_events() or failed
	failed = not _test_combat_defeat_ends_run() or failed
	failed = not _test_stage_1_player_flow_reaches_exit() or failed
	failed = not _test_stage_2_exit_ends_prototype_run() or failed
	quit(1 if failed else 0)


func _test_victory_grants_xp_and_level_events() -> bool:
	var controller := RunController.new()
	controller.setup(StageFixtureCatalog.STAGE_1_DEFAULT_SEED, FLOW_HEALTH_BUDGET, 3)
	controller.start_stage_1()
	controller.run_state.xp = 7

	var first_step := controller.move_player(Vector2i.RIGHT)
	var second_step := controller.move_player(Vector2i.RIGHT)
	var encounter_result := controller.move_player(Vector2i.RIGHT)
	controller.active_combat.enemies[0].health = 0
	var victory_result := controller.finish_active_combat_victory()
	var level_events: Array = victory_result["level_events"]

	var ok := true
	ok = _assert_eq(controller.xp_reward_for_tile_type(DungeonTile.TileType.ENEMY), 3, "normal enemy xp reward") and ok
	ok = _assert_eq(controller.xp_reward_for_tile_type(DungeonTile.TileType.ELITE), 8, "elite xp reward") and ok
	ok = _assert_eq(controller.xp_reward_for_tile_type(DungeonTile.TileType.BOSS), 14, "boss xp reward") and ok
	ok = _assert_eq(first_step["type"], DungeonMapState.EVENT_MOVED, "approach first enemy step 1") and ok
	ok = _assert_eq(second_step["type"], DungeonMapState.EVENT_MOVED, "approach first enemy step 2") and ok
	ok = _assert_eq(encounter_result["type"], RunController.EVENT_COMBAT_STARTED, "first enemy starts combat") and ok
	ok = _assert_eq(victory_result["type"], RunController.EVENT_COMBAT_WON, "victory event") and ok
	ok = _assert_eq(victory_result["xp_gained"], 3, "victory grants normal enemy xp") and ok
	ok = _assert_eq(level_events.size(), 1, "victory can emit level up") and ok
	if level_events.size() > 0:
		ok = _assert_eq(level_events[0]["level"], 2, "level event level") and ok
		ok = _assert_eq(level_events[0]["next_level_xp"], 20, "level event next threshold") and ok
	ok = _assert_eq(controller.run_state.level, 2, "run state level updated") and ok
	ok = _assert_eq(controller.run_state.xp, 0, "xp overflow after exact level up") and ok
	ok = _assert_eq(controller.run_state.next_level_xp, 20, "run state next threshold updated") and ok
	return ok


func _test_combat_defeat_ends_run() -> bool:
	var controller := RunController.new()
	controller.setup(StageFixtureCatalog.STAGE_1_DEFAULT_SEED, 1, 3)
	controller.start_stage_1()
	controller.move_player(Vector2i.RIGHT)
	controller.move_player(Vector2i.RIGHT)
	var encounter_result := controller.move_player(Vector2i.RIGHT)
	var defeat_result := controller.end_turn()
	var move_result := controller.move_player(Vector2i.LEFT)

	var ok := true
	ok = _assert_eq(encounter_result["type"], RunController.EVENT_COMBAT_STARTED, "low-health run starts combat") and ok
	ok = _assert_eq(defeat_result["type"], RunController.EVENT_COMBAT_LOST, "enemy turn can defeat player") and ok
	ok = _assert_eq(controller.mode, RunController.MODE_RUN_END, "combat defeat ends run") and ok
	ok = _assert_eq(controller.active_run_end_reason, "defeat", "run end reason records defeat") and ok
	ok = _assert_eq(controller.active_combat == null, true, "run end clears active combat") and ok
	ok = _assert_eq(move_result["type"], RunController.EVENT_COMMAND_REJECTED, "run end blocks exploration") and ok
	return ok


func _test_stage_1_player_flow_reaches_exit() -> bool:
	var controller := RunController.new()
	controller.setup(StageFixtureCatalog.STAGE_1_DEFAULT_SEED, FLOW_HEALTH_BUDGET, 3)
	var map: DungeonMapState = controller.start_stage_1()

	var ok := true
	ok = _assert_eq(map.is_exit_unlocked(), false, "流程开始时出口锁定") and ok
	ok = _defeat_boss(controller) and ok
	ok = _collect_first_reachable_pickup(controller) and ok
	ok = _assert_eq(map.is_exit_unlocked(), true, "击败首领后出口解锁") and ok
	ok = _request_stage_exit(controller) and ok
	ok = _assert_eq(controller.run_state.current_stage.id, "stage_2", "第 1 关出口进入第 2 关") and ok
	ok = _assert_eq(controller.mode, RunController.MODE_EXPLORATION, "进入第 2 关后回到探索") and ok
	ok = _assert_eq(controller.run_state.health > 0, true, "流程结束时玩家仍存活") and ok
	return ok


func _test_stage_2_exit_ends_prototype_run() -> bool:
	var controller := RunController.new()
	controller.setup(StageFixtureCatalog.STAGE_1_DEFAULT_SEED, FLOW_HEALTH_BUDGET, 3)
	var map: DungeonMapState = controller.run_state.start_stage_2()
	map.mark_enemy_defeated(_find_boss_id(map))
	map.player_position = Vector2i(15, 1)

	var result := controller.move_player(Vector2i.RIGHT)

	var ok := true
	ok = _assert_eq(result["type"], RunController.EVENT_RUN_WON, "stage 2 exit ends prototype run") and ok
	ok = _assert_eq(controller.mode, RunController.MODE_RUN_END, "prototype victory enters run end mode") and ok
	ok = _assert_eq(controller.active_run_end_reason, "victory", "run end reason records victory") and ok
	ok = _assert_eq(controller.active_run_end_title, "原型通关", "run end victory title") and ok
	return ok


func _collect_first_reachable_pickup(controller: RunController) -> bool:
	var map: DungeonMapState = controller.run_state.dungeon_map
	var target_position := _find_first_reachable_pickup(map)
	if target_position == INVALID_POSITION:
		push_error("未找到可抵达的拾取物")
		return false

	var route := _find_path_to_position(map, target_position)
	if not bool(route["found"]):
		push_error("拾取物存在但无法寻路抵达")
		return false

	var before_count := map.collected_pickup_ids.size()
	var result := _walk_path(controller, route["path"])

	var ok := true
	ok = _assert_eq(result["type"], DungeonMapState.EVENT_PICKUP_COLLECTED, "抵达拾取物会触发收集") and ok
	ok = _assert_eq(map.collected_pickup_ids.size(), before_count + 1, "拾取物会记录为已收集") and ok
	if controller.mode == RunController.MODE_REWARD:
		ok = _resolve_pending_rewards(controller) and ok
	return ok


func _defeat_boss(controller: RunController) -> bool:
	var map: DungeonMapState = controller.run_state.dungeon_map
	for _step in range(map.active_enemy_count()):
		var boss_position := _find_boss_position(map)
		if boss_position == INVALID_POSITION:
			return _assert_eq(not map.defeated_boss_ids.is_empty(), true, "首领已被击败")

		var boss_route := _find_path_to_adjacent_position(map, boss_position)
		if bool(boss_route["found"]):
			var boss_walk_result := _walk_path(controller, boss_route["path"])
			if str(boss_walk_result["type"]) == DungeonMapState.EVENT_BLOCKED:
				return _assert_eq(boss_walk_result["type"], "not_blocked", "靠近首领的路径不应被阻挡")

			var boss_direction: Vector2i = boss_position - map.player_position
			var boss_encounter_result := controller.move_player(boss_direction)
			var ok := true
			ok = _assert_eq(boss_encounter_result["type"], RunController.EVENT_COMBAT_STARTED, "移动到首领格会开始遭遇") and ok
			ok = _resolve_encounter(controller) and ok
			ok = _assert_eq(not map.defeated_boss_ids.is_empty(), true, "击败首领会记录 boss defeat") and ok
			return ok

		var target := _find_next_reachable_enemy(map)
		if not bool(target["found"]):
			push_error("首领暂不可达，且没有可清理的敌人")
			return false

		var walk_result := _walk_path(controller, target["path"])
		if str(walk_result["type"]) == DungeonMapState.EVENT_BLOCKED:
			return _assert_eq(walk_result["type"], "not_blocked", "靠近阻挡敌人的路径不应被阻挡")

		var enemy_position: Vector2i = target["enemy_position"]
		var encounter_direction: Vector2i = enemy_position - map.player_position
		var encounter_result := controller.move_player(encounter_direction)
		var before_boss_defeat_count := map.defeated_boss_ids.size()
		var ok := true
		ok = _assert_eq(encounter_result["type"], RunController.EVENT_COMBAT_STARTED, "移动到阻挡敌人格会开始遭遇") and ok
		ok = _resolve_encounter(controller) and ok
		ok = _assert_eq(map.defeated_boss_ids.size(), before_boss_defeat_count, "非首领战斗不记录首领击败") and ok
		ok = _assert_eq(map.is_exit_unlocked(), false, "首领存活时出口保持锁定") and ok
		if not ok:
			return false

	push_error("未能在敌人数量上限内击败首领")
	return false


func _request_stage_exit(controller: RunController) -> bool:
	var map: DungeonMapState = controller.run_state.dungeon_map
	var route := _find_path_to_adjacent_position(map, map.exit_position)
	if not bool(route["found"]):
		push_error("出口已解锁但无法靠近")
		return false

	var walk_result := _walk_path(controller, route["path"])
	if str(walk_result["type"]) == DungeonMapState.EVENT_BLOCKED:
		return _assert_eq(walk_result["type"], "not_blocked", "靠近出口的路径不应被阻挡")

	var exit_direction: Vector2i = route["direction"]
	var exit_result := controller.move_player(exit_direction)
	return _assert_eq(exit_result["type"], RunController.EVENT_STAGE_ADVANCED, "移动到第 1 关出口会进入第 2 关")


func _resolve_encounter(controller: RunController) -> bool:
	for _step in range(MAX_ENCOUNTER_STEPS):
		var combat: CombatState = controller.active_combat
		if controller.mode == RunController.MODE_REWARD:
			if not _apply_first_pending_reward(controller):
				return false
			continue
		if controller.mode == RunController.MODE_EXPLORATION and combat == null:
			return true
		if combat == null:
			push_error("遭遇过程中战斗状态丢失")
			return false
		if combat.is_victory():
			return true
		if combat.is_defeat():
			push_error("玩家在遭遇中失败")
			return false

		var hand_index := _choose_next_card(combat)
		if hand_index < 0:
			var turn_result := controller.end_turn()
			if turn_result["type"] == RunController.EVENT_COMMAND_REJECTED:
				push_error("结束回合失败：%s" % turn_result["reason"])
				return false
			continue

		var result := controller.play_card(hand_index)
		if result["type"] == RunController.EVENT_COMMAND_REJECTED:
			push_error("自动出牌失败：%s" % result["reason"])
			return false
		if result["type"] == RunController.EVENT_COMBAT_WON:
			return _resolve_pending_rewards(controller)

	push_error("遭遇未能在步数上限内结束")
	return false


func _resolve_pending_rewards(controller: RunController) -> bool:
	for _step in range(MAX_ENCOUNTER_STEPS):
		if controller.mode == RunController.MODE_EXPLORATION:
			return true
		if controller.mode != RunController.MODE_REWARD:
			push_error("奖励结算时进入了未知模式：%s" % controller.mode)
			return false
		if not _apply_first_pending_reward(controller):
			return false
	push_error("奖励未能在步数上限内结算")
	return false


func _apply_first_pending_reward(controller: RunController) -> bool:
	if controller.pending_reward_choices.is_empty():
		push_error("升级奖励缺少选项")
		return false
	var result := controller.apply_reward_choice_index(0)
	if result["type"] != RunController.EVENT_REWARD_APPLIED:
		push_error("自动选择升级奖励失败：%s" % result["reason"])
		return false
	return true


func _choose_next_card(combat: CombatState) -> int:
	var fallback_index := -1
	for i in range(combat.deck.hand.size()):
		var card: CardDefinition = combat.deck.hand[i]
		if card.cost > combat.mana:
			continue
		if fallback_index < 0:
			fallback_index = i
		if card.needs_enemy_target() and card.base_damage > 0:
			return i
	return fallback_index


func _find_first_reachable_pickup(map: DungeonMapState) -> Vector2i:
	var best_position := INVALID_POSITION
	var best_length := 999999
	for y in range(map.height):
		for x in range(map.width):
			var position := Vector2i(x, y)
			var tile: DungeonTile = map.get_tile(position)
			if tile == null or not tile.is_pickup_tile():
				continue
			var route := _find_path_to_position(map, position)
			if bool(route["found"]):
				var path: Array = route["path"]
				if path.size() < best_length:
					best_length = path.size()
					best_position = position
	return best_position


func _find_next_reachable_enemy(map: DungeonMapState) -> Dictionary:
	var best := {
		"found": false,
		"enemy_position": INVALID_POSITION,
		"path": [],
	}
	var best_length := 999999
	for enemy_id in map.enemy_positions.keys():
		var enemy_position: Vector2i = map.enemy_positions[enemy_id]
		var route := _find_path_to_adjacent_position(map, enemy_position)
		if not bool(route["found"]):
			continue
		var path: Array = route["path"]
		if path.size() < best_length:
			best_length = path.size()
			best = {
				"found": true,
				"enemy_position": enemy_position,
				"path": path,
			}
	return best


func _find_boss_position(map: DungeonMapState) -> Vector2i:
	for enemy_id in map.enemy_positions.keys():
		var enemy_position: Vector2i = map.enemy_positions[enemy_id]
		var tile: DungeonTile = map.get_tile(enemy_position)
		if tile != null and tile.tile_type == DungeonTile.TileType.BOSS:
			return enemy_position
	return INVALID_POSITION


func _find_boss_id(map: DungeonMapState) -> String:
	for enemy_id in map.enemy_positions.keys():
		var enemy_position: Vector2i = map.enemy_positions[enemy_id]
		var tile: DungeonTile = map.get_tile(enemy_position)
		if tile != null and tile.tile_type == DungeonTile.TileType.BOSS:
			return enemy_id
	return ""


func _find_path_to_adjacent_position(map: DungeonMapState, target_position: Vector2i) -> Dictionary:
	var best := {
		"found": false,
		"path": [],
		"direction": Vector2i.ZERO,
	}
	var best_length := 999999
	for raw_direction in _directions():
		var direction: Vector2i = raw_direction
		var approach_position := target_position - direction
		if approach_position != map.player_position and not _is_walkable_position(map, approach_position):
			continue
		var route := _find_path_to_position(map, approach_position)
		if not bool(route["found"]):
			continue
		var path: Array = route["path"]
		if path.size() < best_length:
			best_length = path.size()
			best = {
				"found": true,
				"path": path,
				"direction": direction,
			}
	return best


func _find_path_to_position(map: DungeonMapState, target_position: Vector2i) -> Dictionary:
	var start_position := map.player_position
	if start_position == target_position:
		return {
			"found": true,
			"path": [],
		}

	var queue: Array = [start_position]
	var came_from: Dictionary = {start_position: start_position}
	var came_direction: Dictionary = {}
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for raw_direction in _directions():
			var direction: Vector2i = raw_direction
			var next_position := current + direction
			if came_from.has(next_position):
				continue
			if not _is_walkable_position(map, next_position):
				continue
			came_from[next_position] = current
			came_direction[next_position] = direction
			if next_position == target_position:
				return {
					"found": true,
					"path": _reconstruct_path(start_position, target_position, came_from, came_direction),
				}
			queue.append(next_position)

	return {
		"found": false,
		"path": [],
	}


func _reconstruct_path(
	start_position: Vector2i,
	target_position: Vector2i,
	came_from: Dictionary,
	came_direction: Dictionary
) -> Array:
	var path: Array = []
	var current_position := target_position
	while current_position != start_position:
		var direction: Vector2i = came_direction[current_position]
		path.append(direction)
		current_position = came_from[current_position]
	path.reverse()
	return path


func _walk_path(controller: RunController, path: Array) -> Dictionary:
	var result: Dictionary = {
		"type": DungeonMapState.EVENT_NO_OP,
		"reason": "",
	}
	for raw_direction in path:
		var direction: Vector2i = raw_direction
		result = controller.move_player(direction)
		var event_type := str(result["type"])
		if event_type == DungeonMapState.EVENT_BLOCKED or event_type == DungeonMapState.EVENT_ENCOUNTER_STARTED:
			push_error("寻路路径被中断：%s" % event_type)
			return result
		if event_type == DungeonMapState.EVENT_PICKUP_COLLECTED and controller.mode == RunController.MODE_REWARD:
			if not _resolve_pending_rewards(controller):
				return result
	return result


func _is_walkable_position(map: DungeonMapState, position: Vector2i) -> bool:
	if not map.is_in_bounds(position):
		return false
	var tile: DungeonTile = map.get_tile(position)
	if tile == null:
		return false
	if tile.tile_type == DungeonTile.TileType.WALL:
		return false
	if tile.is_enemy_tile():
		return false
	return true


func _directions() -> Array:
	return [
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.UP,
	]


func _assert_eq(actual, expected, label: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		return false
	return true
