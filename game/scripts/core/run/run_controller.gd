class_name RunController
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const CardPlayResult = preload("res://scripts/core/combat/card_play_result.gd")
const CombatState = preload("res://scripts/core/combat/combat_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")
const DungeonMapState = preload("res://scripts/core/dungeon/dungeon_map_state.gd")
const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const StarterCardCatalog = preload("res://scripts/core/cards/starter_card_catalog.gd")

const MODE_EXPLORATION := "exploration"
const MODE_COMBAT := "combat"

const EVENT_COMMAND_REJECTED := "command_rejected"
const EVENT_COMBAT_STARTED := "combat_started"
const EVENT_CARD_PLAYED := "card_played"
const EVENT_TURN_ENDED := "turn_ended"
const EVENT_COMBAT_WON := "combat_won"
const EVENT_COMBAT_LOST := "combat_lost"

var run_state: RunState = RunState.new()
var mode: String = MODE_EXPLORATION
var active_combat: CombatState
var active_encounter_id: String = ""
var active_encounter_position: Vector2i = Vector2i.ZERO


func setup(seed: int = 1, max_health: int = 40, max_mana: int = 3) -> void:
	run_state.setup(seed, max_health, max_mana)
	_clear_active_encounter()


func start_stage_1() -> DungeonMapState:
	_clear_active_encounter()
	return run_state.start_stage_1()


func move_player(direction: Vector2i) -> Dictionary:
	if mode != MODE_EXPLORATION:
		return _event(EVENT_COMMAND_REJECTED, "not_in_exploration")
	if run_state.dungeon_map == null:
		return _event(EVENT_COMMAND_REJECTED, "missing_map")

	var result: Dictionary = run_state.dungeon_map.move_player(direction)
	if str(result["type"]) == DungeonMapState.EVENT_ENCOUNTER_STARTED:
		var tile: DungeonTile = run_state.dungeon_map.get_tile(result["to"])
		if tile == null:
			return _event(EVENT_COMMAND_REJECTED, "missing_tile")
		return _start_encounter_for_tile(result["to"], tile)
	return result


func start_encounter_at(position: Vector2i) -> Dictionary:
	if mode != MODE_EXPLORATION:
		return _event(EVENT_COMMAND_REJECTED, "not_in_exploration")
	if run_state.dungeon_map == null:
		return _event(EVENT_COMMAND_REJECTED, "missing_map")

	var tile: DungeonTile = run_state.dungeon_map.get_tile(position)
	if tile == null:
		return _event(EVENT_COMMAND_REJECTED, "missing_tile")
	if not tile.is_enemy_tile():
		return _event(EVENT_COMMAND_REJECTED, "not_enemy")
	if not _is_adjacent(position, run_state.dungeon_map.player_position):
		return _event(EVENT_COMMAND_REJECTED, "not_adjacent")

	return _start_encounter_for_tile(position, tile)


func _start_encounter_for_tile(position: Vector2i, tile: DungeonTile) -> Dictionary:
	mode = MODE_COMBAT
	active_encounter_id = tile.occupant_id
	active_encounter_position = position
	active_combat = _create_combat_for_tile(tile)

	var result := _event(EVENT_COMBAT_STARTED)
	result["encounter_id"] = active_encounter_id
	result["position"] = active_encounter_position
	result["enemy_name"] = _active_enemy_display_name()
	return result


func play_card(hand_index: int) -> Dictionary:
	if mode != MODE_COMBAT or active_combat == null:
		return _event(EVENT_COMMAND_REJECTED, "not_in_combat")

	var card: CardDefinition = null
	if hand_index >= 0 and hand_index < active_combat.deck.hand.size():
		card = active_combat.deck.hand[hand_index]
	var target_index := 0 if card != null and card.needs_enemy_target() else -1
	var play_result: CardPlayResult = active_combat.play_card(hand_index, target_index)
	if not play_result.ok:
		var rejected := _event(EVENT_COMMAND_REJECTED, play_result.reason)
		rejected["play_result"] = play_result
		return rejected

	run_state.health = active_combat.player.health
	if active_combat.is_victory():
		var victory := finish_active_combat_victory()
		_add_play_result_fields(victory, card, play_result)
		return victory

	var result := _event(EVENT_CARD_PLAYED)
	_add_play_result_fields(result, card, play_result)
	return result


func end_turn() -> Dictionary:
	if mode != MODE_COMBAT or active_combat == null:
		return _event(EVENT_COMMAND_REJECTED, "not_in_combat")

	var damage_taken := active_combat.end_player_turn()
	run_state.health = active_combat.player.health
	var result := _event(EVENT_TURN_ENDED)
	result["damage_taken"] = damage_taken
	if active_combat.is_defeat():
		result["type"] = EVENT_COMBAT_LOST
	return result


func finish_active_combat_victory() -> Dictionary:
	if mode != MODE_COMBAT or active_combat == null:
		return _event(EVENT_COMMAND_REJECTED, "not_in_combat")

	run_state.health = active_combat.player.health
	var defeated_name := _active_enemy_display_name()
	var defeated_position := active_encounter_position
	var cleared := false
	if run_state.dungeon_map != null and active_encounter_id != "":
		cleared = run_state.dungeon_map.mark_enemy_defeated(active_encounter_id)

	_clear_active_encounter()

	var result := _event(EVENT_COMBAT_WON)
	result["defeated_name"] = defeated_name
	result["position"] = defeated_position
	result["cleared"] = cleared
	return result


func create_enemy_for_tile(tile: DungeonTile) -> CombatantState:
	if tile.tile_type == DungeonTile.TileType.ELITE:
		return CombatantState.new(tile.occupant_id, "精英", 28, 6)
	if tile.tile_type == DungeonTile.TileType.BOSS:
		return CombatantState.new(tile.occupant_id, "首领", 42, 8)
	return CombatantState.new(tile.occupant_id, "敌人", 16, 4)


func _create_combat_for_tile(tile: DungeonTile) -> CombatState:
	var enemy := create_enemy_for_tile(tile)
	var player := CombatantState.new("hero", "英雄", run_state.max_health, 0, run_state.health)
	var combat := CombatState.new()
	var defeated_count := 0
	if run_state.dungeon_map != null:
		defeated_count = run_state.dungeon_map.defeated_enemy_ids.size()
	combat.setup(
		player,
		StarterCardCatalog.create_starter_deck(),
		[enemy],
		run_state.seed + run_state.stage_index + defeated_count,
		run_state.max_mana,
		5
	)
	return combat


func _active_enemy_display_name() -> String:
	if active_combat != null and not active_combat.enemies.is_empty():
		var enemy: CombatantState = active_combat.enemies[0]
		return enemy.display_name
	return "敌人"


func _clear_active_encounter() -> void:
	mode = MODE_EXPLORATION
	active_combat = null
	active_encounter_id = ""
	active_encounter_position = Vector2i.ZERO


func _add_play_result_fields(event: Dictionary, card: CardDefinition, play_result: CardPlayResult) -> void:
	event["play_result"] = play_result
	event["card_display_name"] = card.display_name if card != null else ""
	event["damage_dealt"] = play_result.damage_dealt
	event["block_gained"] = play_result.block_gained
	event["cards_drawn"] = play_result.cards_drawn


func _event(event_type: String, reason: String = "") -> Dictionary:
	return {
		"type": event_type,
		"reason": reason,
	}


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta := a - b
	return abs(delta.x) + abs(delta.y) == 1
