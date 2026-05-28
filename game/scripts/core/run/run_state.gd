class_name RunState
extends RefCounted

const DungeonMapState = preload("res://scripts/core/dungeon/dungeon_map_state.gd")
const StageConfig = preload("res://scripts/core/dungeon/stage_config.gd")
const StageFixtureCatalog = preload("res://scripts/core/dungeon/stage_fixture_catalog.gd")

var seed: int = 1
var stage_index: int = 0
var current_stage: StageConfig
var dungeon_map: DungeonMapState
var max_health: int = 40
var health: int = 40
var max_mana: int = 3
var level: int = 1
var xp: int = 0
var next_level_xp: int = 10
var deck_card_ids: Array = []
var item_ids: Array = []


func setup(p_seed: int = 1, p_max_health: int = 40, p_max_mana: int = 3) -> void:
	seed = p_seed
	stage_index = 0
	max_health = max(p_max_health, 1)
	health = max_health
	max_mana = max(p_max_mana, 0)
	level = 1
	xp = 0
	next_level_xp = 10
	deck_card_ids = [
		"strike",
		"strike",
		"strike",
		"bolt",
		"bolt",
		"guard",
		"guard",
		"focus",
	]
	item_ids.clear()
	current_stage = null
	dungeon_map = null


func start_stage(stage_config: StageConfig, rows: Array) -> DungeonMapState:
	stage_index += 1
	current_stage = stage_config.duplicate_config()
	dungeon_map = DungeonMapState.new()
	dungeon_map.setup_from_rows(current_stage, rows)
	return dungeon_map


func start_stage_1() -> DungeonMapState:
	return start_stage(StageFixtureCatalog.create_stage_1_config(seed), StageFixtureCatalog.stage_1_rows())


func gain_xp(amount: int) -> Array:
	var level_events: Array = []
	xp += max(amount, 0)
	while xp >= next_level_xp:
		xp -= next_level_xp
		level += 1
		next_level_xp += 10
		level_events.append({
			"type": "level_up",
			"level": level,
			"next_level_xp": next_level_xp,
		})
	return level_events


func add_card(card_id: String) -> void:
	if card_id != "":
		deck_card_ids.append(card_id)


func add_item(item_id: String) -> void:
	if item_id != "" and not item_ids.has(item_id):
		item_ids.append(item_id)
