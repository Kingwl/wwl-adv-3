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
		return CombatantState.new(enemy_id, "刺蝠", 8, 6)
	if catalog_id == ID_GUARD:
		return CombatantState.new(enemy_id, "盾卫", 16, 3, -1, 5)
	if catalog_id == ID_BRUTE:
		return CombatantState.new(enemy_id, "重甲兵", 24, 5, -1, 6)
	if catalog_id == ID_BOSS_GUARD:
		return CombatantState.new(enemy_id, "首领护卫", 18, 4, -1, 5)
	if catalog_id == ID_STAGE_BOSS:
		return CombatantState.new(enemy_id, "首领", 42, 8)
	return CombatantState.new(enemy_id, "走卒", 12, 4)
