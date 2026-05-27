class_name CardDefinition
extends RefCounted

enum TargetMode {
	NONE,
	SINGLE_ENEMY,
	ALL_ENEMIES,
	SELF,
}

var id: String
var display_name: String
var cost: int
var base_damage: int
var block: int
var draw_count: int
var target_mode: int


func _init(
	p_id: String = "",
	p_display_name: String = "",
	p_cost: int = 0,
	p_base_damage: int = 0,
	p_block: int = 0,
	p_draw_count: int = 0,
	p_target_mode: int = TargetMode.NONE
) -> void:
	id = p_id
	display_name = p_display_name
	cost = max(p_cost, 0)
	base_damage = max(p_base_damage, 0)
	block = max(p_block, 0)
	draw_count = max(p_draw_count, 0)
	target_mode = p_target_mode


func duplicate_definition():
	return get_script().new(
		id,
		display_name,
		cost,
		base_damage,
		block,
		draw_count,
		target_mode
	)


func is_attack() -> bool:
	return base_damage > 0


func needs_enemy_target() -> bool:
	return target_mode == TargetMode.SINGLE_ENEMY
