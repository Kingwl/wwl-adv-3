extends SceneTree

const DungeonMapState = preload("res://scripts/core/dungeon/dungeon_map_state.gd")
const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const RunController = preload("res://scripts/core/run/run_controller.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const StageConfig = preload("res://scripts/core/dungeon/stage_config.gd")
const StageFixtureCatalog = preload("res://scripts/core/dungeon/stage_fixture_catalog.gd")


func _init() -> void:
	var failed := false
	failed = not _test_fixture_loads_deterministic_map() or failed
	failed = not _test_movement_blocks_walls_bounds_and_diagonals() or failed
	failed = not _test_enemy_tiles_start_encounters_without_moving_player() or failed
	failed = not _test_pickups_are_collected_once() or failed
	failed = not _test_defeats_unlock_exit() or failed
	failed = not _test_boss_defeat_unlocks_stage_1_exit() or failed
	failed = not _test_run_state_starts_stage() or failed
	failed = not _test_run_state_xp_curve_keeps_stage_1_balanced() or failed
	failed = not _test_stage_1_fixture_matches_budget() or failed
	failed = not _test_run_state_starts_stage_1() or failed
	quit(1 if failed else 0)


func _test_fixture_loads_deterministic_map() -> bool:
	var config := _stage_config(2)
	var rows := [
		"#######",
		"#P.m.C#",
		"#..#..#",
		"#..B.E#",
		"#######",
	]
	var first_map := DungeonMapState.new()
	var second_map := DungeonMapState.new()
	first_map.setup_from_rows(config, rows)
	second_map.setup_from_rows(config, rows)

	var ok := true
	ok = _assert_eq(first_map.width, 7, "fixture width") and ok
	ok = _assert_eq(first_map.height, 5, "fixture height") and ok
	ok = _assert_eq(first_map.player_position, Vector2i(1, 1), "fixture player position") and ok
	ok = _assert_eq(first_map.exit_position, Vector2i(5, 3), "fixture exit position") and ok
	ok = _assert_eq(first_map.active_enemy_count(), 2, "fixture enemy count") and ok
	ok = _assert_eq(first_map.active_pickup_count(), 1, "fixture pickup count") and ok
	ok = _assert_eq(first_map.to_debug_string(), second_map.to_debug_string(), "fixture is deterministic") and ok
	return ok


func _test_movement_blocks_walls_bounds_and_diagonals() -> bool:
	var map := DungeonMapState.new()
	map.setup_from_rows(_stage_config(0), [
		"###",
		"#P.",
		"###",
	])

	var wall_result := map.move_player(Vector2i(-1, 0))
	var diagonal_result := map.move_player(Vector2i(1, 1))
	var move_result := map.move_player(Vector2i(1, 0))
	var bounds_result := map.move_player(Vector2i(1, 0))

	var ok := true
	ok = _assert_eq(wall_result["type"], DungeonMapState.EVENT_BLOCKED, "wall blocks movement") and ok
	ok = _assert_eq(wall_result["reason"], "wall", "wall block reason") and ok
	ok = _assert_eq(diagonal_result["reason"], "non_cardinal_direction", "diagonal block reason") and ok
	ok = _assert_eq(move_result["type"], DungeonMapState.EVENT_MOVED, "floor allows movement") and ok
	ok = _assert_eq(map.player_position, Vector2i(2, 1), "player moved onto floor") and ok
	ok = _assert_eq(bounds_result["reason"], "out_of_bounds", "bounds block reason") and ok
	return ok


func _test_enemy_tiles_start_encounters_without_moving_player() -> bool:
	var map := DungeonMapState.new()
	map.setup_from_rows(_stage_config(1), [
		"#####",
		"#PmE#",
		"#####",
	])

	var result := map.move_player(Vector2i(1, 0))

	var ok := true
	ok = _assert_eq(result["type"], DungeonMapState.EVENT_ENCOUNTER_STARTED, "enemy starts encounter") and ok
	ok = _assert_eq(result["occupant_id"], "enemy_01", "enemy event id") and ok
	ok = _assert_eq(map.player_position, Vector2i(1, 1), "enemy blocks movement") and ok
	return ok


func _test_pickups_are_collected_once() -> bool:
	var map := DungeonMapState.new()
	map.setup_from_rows(_stage_config(0), [
		"#####",
		"#PC.#",
		"#####",
	])

	var pickup_result := map.move_player(Vector2i(1, 0))
	var move_back_result := map.move_player(Vector2i(-1, 0))
	var repeat_result := map.move_player(Vector2i(1, 0))

	var ok := true
	ok = _assert_eq(pickup_result["type"], DungeonMapState.EVENT_PICKUP_COLLECTED, "pickup event") and ok
	ok = _assert_eq(pickup_result["occupant_id"], "treasure_01", "pickup id") and ok
	ok = _assert_eq(map.collected_pickup_ids, ["treasure_01"], "pickup collected once") and ok
	ok = _assert_eq(map.active_pickup_count(), 0, "pickup removed") and ok
	ok = _assert_eq(move_back_result["type"], DungeonMapState.EVENT_MOVED, "can leave pickup tile") and ok
	ok = _assert_eq(repeat_result["type"], DungeonMapState.EVENT_MOVED, "collected pickup becomes floor") and ok
	return ok


func _test_defeats_unlock_exit() -> bool:
	var map := DungeonMapState.new()
	map.setup_from_rows(_stage_config(1), [
		"#####",
		"#PmE#",
		"#####",
	])

	var locked_result := map.move_player(Vector2i(1, 0))
	var marked := map.mark_enemy_defeated("enemy_01")
	var move_result := map.move_player(Vector2i(1, 0))
	var exit_result := map.move_player(Vector2i(1, 0))

	var ok := true
	ok = _assert_eq(locked_result["type"], DungeonMapState.EVENT_ENCOUNTER_STARTED, "enemy protects exit") and ok
	ok = _assert_eq(marked, true, "enemy marked defeated") and ok
	ok = _assert_eq(map.is_exit_unlocked(), true, "exit unlocked after required defeat") and ok
	ok = _assert_eq(move_result["type"], DungeonMapState.EVENT_MOVED, "defeated enemy tile becomes floor") and ok
	ok = _assert_eq(exit_result["type"], DungeonMapState.EVENT_STAGE_EXIT_REQUESTED, "exit interaction") and ok
	return ok


func _test_boss_defeat_unlocks_stage_1_exit() -> bool:
	var map := StageFixtureCatalog.create_stage_1_map(404)
	var marked := map.mark_enemy_defeated("boss_11")
	map.player_position = Vector2i(13, 1)
	var exit_result := map.move_player(Vector2i.RIGHT)

	var ok := true
	ok = _assert_eq(marked, true, "stage 1 boss id can be marked defeated") and ok
	ok = _assert_eq(map.is_exit_unlocked(), true, "stage 1 boss defeat unlocks exit") and ok
	ok = _assert_eq(exit_result["type"], DungeonMapState.EVENT_STAGE_EXIT_REQUESTED, "stage 1 exit responds after boss defeat") and ok
	return ok


func _test_run_state_starts_stage() -> bool:
	var run := RunState.new()
	run.setup(99)
	var map := run.start_stage(_stage_config(1), [
		"#####",
		"#PmE#",
		"#####",
	])
	var level_events := run.gain_xp(10)

	var ok := true
	ok = _assert_eq(run.seed, 99, "run seed") and ok
	ok = _assert_eq(run.stage_index, 1, "run stage index") and ok
	ok = _assert_eq(run.health, 40, "run starts at full health") and ok
	ok = _assert_eq(run.deck_card_ids.size(), 8, "run starter deck size") and ok
	ok = _assert_eq(map.active_enemy_count(), 1, "run stage map enemy count") and ok
	ok = _assert_eq(level_events.size(), 1, "run levels from xp") and ok
	ok = _assert_eq(run.level, 2, "run level after xp") and ok
	return ok


func _test_run_state_xp_curve_keeps_stage_1_balanced() -> bool:
	var required_path_xp := RunController.XP_REWARD_NORMAL * 7 + RunController.XP_REWARD_ELITE
	var full_stage_xp := (
		RunController.XP_REWARD_NORMAL * 10
		+ RunController.XP_REWARD_ELITE
		+ RunController.XP_REWARD_BOSS
	)
	var unlock_run := RunState.new()
	unlock_run.setup(7)
	var unlock_events := unlock_run.gain_xp(required_path_xp)
	var full_clear_run := RunState.new()
	full_clear_run.setup(7)
	var full_clear_events := full_clear_run.gain_xp(full_stage_xp)

	var ok := true
	ok = _assert_eq(required_path_xp, 29, "stage 1 required path xp budget") and ok
	ok = _assert_eq(unlock_events.size(), 1, "required path gives one level up") and ok
	ok = _assert_eq(unlock_run.level, 2, "required path reaches level 2") and ok
	ok = _assert_eq(unlock_run.xp, 19, "required path stays just short of level 3") and ok
	ok = _assert_eq(unlock_run.next_level_xp, 20, "level 2 threshold") and ok
	ok = _assert_eq(full_stage_xp, 52, "stage 1 full clear xp budget") and ok
	ok = _assert_eq(full_clear_events.size(), 2, "full clear gives two level ups") and ok
	ok = _assert_eq(full_clear_run.level, 3, "full clear reaches level 3") and ok
	ok = _assert_eq(full_clear_run.xp, 22, "full clear remains below level 4") and ok
	ok = _assert_eq(full_clear_run.next_level_xp, 30, "level 3 threshold") and ok
	return ok


func _test_stage_1_fixture_matches_budget() -> bool:
	var config := StageFixtureCatalog.create_stage_1_config(321)
	var map := StageFixtureCatalog.create_stage_1_map(321)

	var ok := true
	ok = _assert_eq(config.id, "stage_1", "stage 1 id") and ok
	ok = _assert_eq(config.seed, 321, "stage 1 seed override") and ok
	ok = _assert_eq(map.width, 16, "stage 1 width") and ok
	ok = _assert_eq(map.height, 10, "stage 1 height") and ok
	ok = _assert_eq(map.active_enemy_count(), config.enemy_budget, "stage 1 enemy budget") and ok
	ok = _assert_eq(map.active_enemy_count(), 12, "stage 1 has 12 enemies") and ok
	ok = _assert_eq(map.active_pickup_count(), config.pickup_budget, "stage 1 pickup budget") and ok
	ok = _assert_eq(map.active_pickup_count(), 3, "stage 1 has 3 pickups") and ok
	ok = _assert_eq(map.exit_position, Vector2i(14, 1), "stage 1 exit position") and ok
	ok = _assert_eq(map.player_position, Vector2i(1, 1), "stage 1 player position") and ok
	ok = _assert_eq(map.is_exit_unlocked(), false, "stage 1 starts locked") and ok
	ok = _assert_eq(_defeat_stage_1_required_enemies(map), true, "stage 1 required defeats can be marked") and ok
	ok = _assert_eq(map.is_exit_unlocked(), true, "stage 1 unlocks after required defeats") and ok
	return ok


func _test_run_state_starts_stage_1() -> bool:
	var run := RunState.new()
	run.setup(515)
	var map := run.start_stage_1()

	var ok := true
	ok = _assert_eq(run.stage_index, 1, "stage 1 increments run stage index") and ok
	ok = _assert_eq(run.current_stage.id, "stage_1", "run current stage id") and ok
	ok = _assert_eq(run.current_stage.seed, 515, "run seed feeds stage 1") and ok
	ok = _assert_eq(map.active_enemy_count(), 12, "run stage 1 enemy count") and ok
	ok = _assert_eq(map.active_pickup_count(), 3, "run stage 1 pickup count") and ok
	return ok


func _stage_config(required_defeats: int) -> StageConfig:
	return StageConfig.new(
		"stage_1",
		"Stage 1",
		123,
		1,
		1,
		required_defeats,
		1,
		required_defeats,
		true,
		StageConfig.ClearCondition.REQUIRED_DEFEATS
	)


func _defeat_stage_1_required_enemies(map: DungeonMapState) -> bool:
	var enemy_ids := [
		"enemy_01",
		"enemy_02",
		"enemy_03",
		"enemy_04",
		"enemy_05",
		"enemy_06",
		"elite_07",
		"enemy_08",
	]
	for enemy_id in enemy_ids:
		if not map.mark_enemy_defeated(enemy_id):
			return false
	return true


func _assert_eq(actual, expected, label: String) -> bool:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [label, str(expected), str(actual)])
		return false
	return true
