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
const STAGE_2_ID := "stage_2"
const STAGE_2_DISPLAY_NAME := "第二关：墓园长廊"
const STAGE_2_SEED_OFFSET := 101
const STAGE_2_WIDTH := 18
const STAGE_2_HEIGHT := 10
const STAGE_2_ENEMY_BUDGET := 12
const STAGE_2_PICKUP_BUDGET := 4
const FINAL_STAGE_INDEX := 2


static func create_stage_1_config(seed_value: int = STAGE_1_DEFAULT_SEED) -> StageConfig:
	return StageConfig.new(
		STAGE_1_ID,
		STAGE_1_DISPLAY_NAME,
		seed_value,
		STAGE_1_WIDTH,
		STAGE_1_HEIGHT,
		STAGE_1_ENEMY_BUDGET,
		STAGE_1_PICKUP_BUDGET,
		0,
		true,
		StageConfig.ClearCondition.BOSS_DEFEATED
	)


static func create_stage_2_config(seed_value: int = STAGE_1_DEFAULT_SEED + STAGE_2_SEED_OFFSET) -> StageConfig:
	return StageConfig.new(
		STAGE_2_ID,
		STAGE_2_DISPLAY_NAME,
		seed_value,
		STAGE_2_WIDTH,
		STAGE_2_HEIGHT,
		STAGE_2_ENEMY_BUDGET,
		STAGE_2_PICKUP_BUDGET,
		0,
		true,
		StageConfig.ClearCondition.BOSS_DEFEATED
	)


static func stage_1_rows() -> Array:
	return [
		"################",
		"#P..m...C..m..E#",
		"#.####.####.##.#",
		"#..m...m...Hm..#",
		"###.###.###.##.#",
		"#m..X..m..e....#",
		"#.####.####.##.#",
		"#..m...m...m...#",
		"#....B.........#",
		"################",
	]


static func stage_2_rows() -> Array:
	return [
		"##################",
		"#P..m...C...m...E#",
		"#.####.####.##.#.#",
		"#..m...H..m...e..#",
		"###.###.###.##.#.#",
		"#m..X..m..F......#",
		"#.####.####.##.#.#",
		"#..m...m...m..m..#",
		"#....B...........#",
		"##################",
	]


static func create_stage_1_map(seed_value: int = STAGE_1_DEFAULT_SEED) -> DungeonMapState:
	var map := DungeonMapState.new()
	map.setup_from_rows(create_stage_1_config(seed_value), stage_1_rows())
	return map


static func create_stage_2_map(seed_value: int = STAGE_1_DEFAULT_SEED + STAGE_2_SEED_OFFSET) -> DungeonMapState:
	var map := DungeonMapState.new()
	map.setup_from_rows(create_stage_2_config(seed_value), stage_2_rows())
	return map
