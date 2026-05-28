class_name StageFixtureCatalog
extends RefCounted

const DungeonMapState = preload("res://scripts/core/dungeon/dungeon_map_state.gd")
const StageConfig = preload("res://scripts/core/dungeon/stage_config.gd")

const STAGE_1_ID := "stage_1"
const STAGE_1_DISPLAY_NAME := "第一关：旧井入口"
const STAGE_1_DEFAULT_SEED := 1001
const STAGE_1_WIDTH := 16
const STAGE_1_HEIGHT := 10
const STAGE_1_ENEMY_BUDGET := 12
const STAGE_1_PICKUP_BUDGET := 3
const STAGE_1_REQUIRED_DEFEATS := 8


static func create_stage_1_config(seed_value: int = STAGE_1_DEFAULT_SEED) -> StageConfig:
	return StageConfig.new(
		STAGE_1_ID,
		STAGE_1_DISPLAY_NAME,
		seed_value,
		STAGE_1_WIDTH,
		STAGE_1_HEIGHT,
		STAGE_1_ENEMY_BUDGET,
		STAGE_1_PICKUP_BUDGET,
		STAGE_1_REQUIRED_DEFEATS,
		true,
		StageConfig.ClearCondition.REQUIRED_DEFEATS_OR_BOSS
	)


static func stage_1_rows() -> Array:
	return [
		"################",
		"#P..m...C..m..E#",
		"#.####.####.##.#",
		"#..m...m...H...#",
		"###.###.###.##.#",
		"#m..F..m..e....#",
		"#.####.####.##.#",
		"#..m...m...m...#",
		"#....B....m....#",
		"################",
	]


static func create_stage_1_map(seed_value: int = STAGE_1_DEFAULT_SEED) -> DungeonMapState:
	var map := DungeonMapState.new()
	map.setup_from_rows(create_stage_1_config(seed_value), stage_1_rows())
	return map
