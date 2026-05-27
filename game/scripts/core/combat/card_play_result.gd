class_name CardPlayResult
extends RefCounted

var ok: bool = true
var reason: String = ""
var card_id: String = ""
var target_id: String = ""
var combo_chain: int = 0
var multiplier_basis_points: int = 100
var mana_spent: int = 0
var damage_requested: int = 0
var damage_dealt: int = 0
var block_gained: int = 0
var cards_drawn: int = 0
var defeated_enemy_ids: Array = []


static func failure(reason_text: String):
	var result = load("res://scripts/core/combat/card_play_result.gd").new()
	result.ok = false
	result.reason = reason_text
	return result
