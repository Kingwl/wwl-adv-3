class_name EnemyCatalog
extends RefCounted

const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")

const ID_GRUNT := "grunt"
const ID_BAT := "bat"
const ID_GUARD := "guard"
const ID_BRUTE := "brute"
const ID_BOSS_GUARD := "boss_guard"
const ID_STAGE_BOSS := "stage_boss"


static func create_enemy(enemy_id: String, catalog_id: String) -> CombatantState:
	if catalog_id == ID_BAT:
		return _enemy(enemy_id, "刺蝠", 8, 6, catalog_id)
	if catalog_id == ID_GUARD:
		return _enemy(enemy_id, "盾卫", 16, 3, catalog_id, 5)
	if catalog_id == ID_BRUTE:
		return _enemy(enemy_id, "重甲兵", 24, 5, catalog_id, 6)
	if catalog_id == ID_BOSS_GUARD:
		return _enemy(enemy_id, "首领护卫", 18, 4, catalog_id, 5)
	if catalog_id == ID_STAGE_BOSS:
		return _enemy(enemy_id, "首领", 42, 8, catalog_id)
	return _enemy(enemy_id, "走卒", 12, 4, ID_GRUNT)


static func _enemy(
	enemy_id: String,
	display_name: String,
	max_health: int,
	attack_damage: int,
	visual_id: String,
	guard_block: int = 0
) -> CombatantState:
	var enemy := CombatantState.new(enemy_id, display_name, max_health, attack_damage, -1, guard_block)
	enemy.visual_id = visual_id
	return enemy
