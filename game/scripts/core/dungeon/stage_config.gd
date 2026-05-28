class_name StageConfig
extends RefCounted

enum ClearCondition {
	REQUIRED_DEFEATS,
	BOSS_DEFEATED,
	REQUIRED_DEFEATS_OR_BOSS,
	EXIT_ONLY,
}

var id: String
var display_name: String
var seed: int
var width: int
var height: int
var enemy_budget: int
var pickup_budget: int
var required_defeats: int
var exit_locked: bool
var clear_condition: int


func _init(
	p_id: String = "stage_1",
	p_display_name: String = "第一关",
	p_seed: int = 1,
	p_width: int = 1,
	p_height: int = 1,
	p_enemy_budget: int = 0,
	p_pickup_budget: int = 0,
	p_required_defeats: int = 0,
	p_exit_locked: bool = true,
	p_clear_condition: int = ClearCondition.REQUIRED_DEFEATS
) -> void:
	id = p_id
	display_name = p_display_name
	seed = p_seed
	width = max(p_width, 1)
	height = max(p_height, 1)
	enemy_budget = max(p_enemy_budget, 0)
	pickup_budget = max(p_pickup_budget, 0)
	required_defeats = max(p_required_defeats, 0)
	exit_locked = p_exit_locked
	clear_condition = p_clear_condition


func duplicate_config():
	return get_script().new(
		id,
		display_name,
		seed,
		width,
		height,
		enemy_budget,
		pickup_budget,
		required_defeats,
		exit_locked,
		clear_condition
	)


func is_exit_unlocked(defeated_count: int, boss_defeated: bool = false) -> bool:
	if not exit_locked:
		return true

	if clear_condition == ClearCondition.REQUIRED_DEFEATS:
		return defeated_count >= required_defeats
	if clear_condition == ClearCondition.BOSS_DEFEATED:
		return boss_defeated
	if clear_condition == ClearCondition.REQUIRED_DEFEATS_OR_BOSS:
		return defeated_count >= required_defeats or boss_defeated
	if clear_condition == ClearCondition.EXIT_ONLY:
		return true

	return false
