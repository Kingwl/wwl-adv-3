class_name CombatantState
extends RefCounted

var id: String
var display_name: String
var max_health: int
var health: int
var block: int
var attack_damage: int


func _init(
	p_id: String = "",
	p_display_name: String = "",
	p_max_health: int = 1,
	p_attack_damage: int = 0,
	p_health: int = -1
) -> void:
	id = p_id
	display_name = p_display_name
	max_health = max(p_max_health, 1)
	attack_damage = max(p_attack_damage, 0)
	block = 0

	if p_health < 0:
		health = max_health
	else:
		health = min(max(p_health, 0), max_health)


func duplicate_state():
	var copy = get_script().new(id, display_name, max_health, attack_damage, health)
	copy.block = block
	return copy


func gain_block(amount: int) -> void:
	block += max(amount, 0)


func clear_block() -> void:
	block = 0


func take_damage(amount: int) -> int:
	var incoming: int = max(amount, 0)
	var absorbed: int = min(block, incoming)
	block -= absorbed

	var damage_to_health: int = incoming - absorbed
	var dealt: int = min(health, damage_to_health)
	health -= dealt
	return dealt


func is_defeated() -> bool:
	return health <= 0
