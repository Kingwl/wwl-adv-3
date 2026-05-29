class_name RunController
extends RefCounted

const CardDefinition = preload("res://scripts/core/cards/card_definition.gd")
const CardPlayResult = preload("res://scripts/core/combat/card_play_result.gd")
const CombatState = preload("res://scripts/core/combat/combat_state.gd")
const CombatantState = preload("res://scripts/core/combat/combatant_state.gd")
const EnemyCatalog = preload("res://scripts/core/combat/enemy_catalog.gd")
const DungeonMapState = preload("res://scripts/core/dungeon/dungeon_map_state.gd")
const DungeonTile = preload("res://scripts/core/dungeon/dungeon_tile.gd")
const RewardGenerator = preload("res://scripts/core/rewards/reward_generator.gd")
const RunState = preload("res://scripts/core/run/run_state.gd")
const StarterCardCatalog = preload("res://scripts/core/cards/starter_card_catalog.gd")

const MODE_EXPLORATION := "exploration"
const MODE_COMBAT := "combat"
const MODE_REWARD := "reward"
const MODE_RUN_END := "run_end"
const REWARD_SOURCE_LEVEL_UP := "level_up"
const REWARD_SOURCE_TREASURE := "treasure"

const EVENT_COMMAND_REJECTED := "command_rejected"
const EVENT_COMBAT_STARTED := "combat_started"
const EVENT_CARD_PLAYED := "card_played"
const EVENT_TURN_ENDED := "turn_ended"
const EVENT_COMBAT_WON := "combat_won"
const EVENT_COMBAT_LOST := "combat_lost"
const EVENT_STAGE_ADVANCED := "stage_advanced"
const EVENT_RUN_WON := "run_won"
const EVENT_REWARD_APPLIED := RewardGenerator.EVENT_REWARD_APPLIED
const EVENT_REWARD_REJECTED := RewardGenerator.EVENT_REWARD_REJECTED

const XP_REWARD_NORMAL := 3
const XP_REWARD_ELITE := 8
const XP_REWARD_BOSS := 14
const XP_GEM_REWARD := 5
const HEALING_PICKUP_AMOUNT := 10

var run_state: RunState = RunState.new()
var mode: String = MODE_EXPLORATION
var active_combat: CombatState
var active_encounter_id: String = ""
var active_encounter_display_name: String = ""
var active_encounter_position: Vector2i = Vector2i.ZERO
var pending_reward_level_events: Array = []
var active_reward_level_event: Dictionary = {}
var active_reward_source: String = ""
var active_reward_title: String = ""
var active_reward_pickup_id: String = ""
var pending_reward_choices: Array = []
var active_run_end_reason: String = ""
var active_run_end_title: String = ""
var active_run_end_summary: String = ""


func setup(seed: int = 1, max_health: int = 40, max_mana: int = 3) -> void:
	run_state.setup(seed, max_health, max_mana)
	_clear_active_encounter()
	_clear_reward_state()
	_clear_run_end_state()


func start_stage_1() -> DungeonMapState:
	_clear_active_encounter()
	_clear_reward_state()
	_clear_run_end_state()
	return run_state.start_stage_1()


func move_player(direction: Vector2i) -> Dictionary:
	if mode != MODE_EXPLORATION:
		return _event(EVENT_COMMAND_REJECTED, "not_in_exploration")
	if run_state.dungeon_map == null:
		return _event(EVENT_COMMAND_REJECTED, "missing_map")

	var result: Dictionary = run_state.dungeon_map.move_player(direction)
	var result_type := str(result["type"])
	if result_type == DungeonMapState.EVENT_ENCOUNTER_STARTED:
		var tile: DungeonTile = run_state.dungeon_map.get_tile(result["to"])
		if tile == null:
			return _event(EVENT_COMMAND_REJECTED, "missing_tile")
		return _start_encounter_for_tile(result["to"], tile)
	if result_type == DungeonMapState.EVENT_PICKUP_COLLECTED:
		_apply_pickup_effect(result)
	if result_type == DungeonMapState.EVENT_STAGE_EXIT_REQUESTED:
		return _advance_stage_or_end_run(result)
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
	active_encounter_display_name = _encounter_display_name_for_tile(tile)
	active_encounter_position = position
	active_combat = _create_combat_for_tile(tile)

	var result := _event(EVENT_COMBAT_STARTED)
	result["encounter_id"] = active_encounter_id
	result["position"] = active_encounter_position
	result["enemy_name"] = active_encounter_display_name
	return result


func play_card(hand_index: int) -> Dictionary:
	if mode != MODE_COMBAT or active_combat == null:
		return _event(EVENT_COMMAND_REJECTED, "not_in_combat")

	var card: CardDefinition = null
	if hand_index >= 0 and hand_index < active_combat.deck.hand.size():
		card = active_combat.deck.hand[hand_index]
	var target_index := active_combat.primary_target_index() if card != null and card.needs_enemy_target() else -1
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
		_start_run_defeat()
		_add_run_end_fields(result)
	return result


func finish_active_combat_victory() -> Dictionary:
	if mode != MODE_COMBAT or active_combat == null:
		return _event(EVENT_COMMAND_REJECTED, "not_in_combat")
	if not active_combat.is_victory():
		return _event(EVENT_COMMAND_REJECTED, "combat_not_won")

	run_state.health = active_combat.player.health
	var defeated_name := active_encounter_display_name
	var defeated_position := active_encounter_position
	var xp_reward := _xp_reward_for_active_encounter()
	var level_events := run_state.gain_xp(xp_reward)
	var cleared := false
	if run_state.dungeon_map != null and active_encounter_id != "":
		cleared = run_state.dungeon_map.mark_enemy_defeated(active_encounter_id)

	_clear_active_encounter()
	if not level_events.is_empty():
		_start_level_rewards(level_events)

	var result := _event(EVENT_COMBAT_WON)
	result["defeated_name"] = defeated_name
	result["position"] = defeated_position
	result["cleared"] = cleared
	result["xp_gained"] = xp_reward
	result["level_events"] = level_events
	result["level"] = run_state.level
	result["xp"] = run_state.xp
	result["next_level_xp"] = run_state.next_level_xp
	result["reward_choices"] = pending_reward_choices.duplicate(true)
	result["reward_level_event"] = active_reward_level_event.duplicate(true)
	result["reward_pending_count"] = pending_reward_level_events.size()
	return result


func create_level_up_reward_choices(level_event: Dictionary = {}) -> Array:
	var reward_level := run_state.level
	if level_event.has("level"):
		reward_level = int(level_event["level"])
	return RewardGenerator.create_stage_1_card_choices(
		run_state.seed,
		run_state.stage_index,
		reward_level,
		run_state.reward_offer_index
	)


func apply_reward_choice(choice: Dictionary) -> Dictionary:
	if mode != MODE_REWARD:
		return _event(EVENT_REWARD_REJECTED, "not_in_reward")
	if pending_reward_choices.is_empty():
		return _event(EVENT_REWARD_REJECTED, "missing_reward_choices")
	if not _choice_is_pending(choice):
		return _event(EVENT_REWARD_REJECTED, "invalid_reward_choice")

	var result := RewardGenerator.apply_choice(run_state, choice)
	if bool(result.get("ok", false)):
		run_state.reward_offer_index += 1
		var applied_level_event := active_reward_level_event.duplicate(true)
		var applied_reward_source := active_reward_source
		var applied_reward_title := active_reward_title
		var applied_reward_pickup_id := active_reward_pickup_id
		var remaining_before_advance := pending_reward_level_events.size()
		if remaining_before_advance > 0:
			_start_next_queued_reward()
		else:
			_clear_reward_state()
			mode = MODE_EXPLORATION
		result["level_event"] = applied_level_event
		result["reward_source"] = applied_reward_source
		result["reward_title"] = applied_reward_title
		result["pickup_id"] = applied_reward_pickup_id
		result["reward_choices"] = pending_reward_choices.duplicate(true)
		result["reward_pending_count"] = pending_reward_level_events.size()
	return result


func apply_reward_choice_index(choice_index: int) -> Dictionary:
	if mode != MODE_REWARD:
		return _event(EVENT_REWARD_REJECTED, "not_in_reward")
	if choice_index < 0 or choice_index >= pending_reward_choices.size():
		return _event(EVENT_REWARD_REJECTED, "invalid_reward_index")
	return apply_reward_choice(pending_reward_choices[choice_index])


func xp_reward_for_tile_type(tile_type: int) -> int:
	if tile_type == DungeonTile.TileType.ELITE:
		return XP_REWARD_ELITE
	if tile_type == DungeonTile.TileType.BOSS:
		return XP_REWARD_BOSS
	if tile_type == DungeonTile.TileType.ENEMY:
		return XP_REWARD_NORMAL
	return 0


func create_enemy_for_tile(tile: DungeonTile) -> CombatantState:
	if tile.tile_type == DungeonTile.TileType.ELITE:
		return _create_enemy(tile, "front", EnemyCatalog.ID_BRUTE)
	if tile.tile_type == DungeonTile.TileType.BOSS:
		return _create_enemy(tile, "guard", EnemyCatalog.ID_BOSS_GUARD)
	return _create_enemy(tile, "front", EnemyCatalog.ID_GRUNT)


func create_enemy_rows_for_tile(tile: DungeonTile) -> Array:
	if tile.tile_type == DungeonTile.TileType.ELITE:
		return _elite_enemy_rows(tile)
	if tile.tile_type == DungeonTile.TileType.BOSS:
		return _boss_enemy_rows(tile)
	return _normal_enemy_rows(tile)


func _normal_enemy_rows(tile: DungeonTile) -> Array:
	var serial := _encounter_serial(tile)
	if run_state.stage_index >= 2:
		if serial % 4 == 1:
			return [[
				_create_enemy(tile, "guard", EnemyCatalog.ID_GUARD),
				_create_enemy(tile, "bat", EnemyCatalog.ID_BAT),
			], [
				_create_enemy(tile, "grunt", EnemyCatalog.ID_GRUNT),
			]]
		if serial % 4 == 2:
			return [[
				_create_enemy(tile, "brute", EnemyCatalog.ID_BRUTE),
			], [
				_create_enemy(tile, "bat", EnemyCatalog.ID_BAT),
			]]
		if serial % 4 == 3:
			return [[
				_create_enemy(tile, "bat", EnemyCatalog.ID_BAT),
				_create_enemy(tile, "grunt", EnemyCatalog.ID_GRUNT),
			], [
				_create_enemy(tile, "guard", EnemyCatalog.ID_GUARD),
			]]
		return [[
			_create_enemy(tile, "guard", EnemyCatalog.ID_GUARD),
		], [
			_create_enemy(tile, "brute", EnemyCatalog.ID_BRUTE),
		]]

	if serial % 4 == 1:
		return [[
			_create_enemy(tile, "grunt", EnemyCatalog.ID_GRUNT),
		], [
			_create_enemy(tile, "rear_grunt", EnemyCatalog.ID_GRUNT),
		]]
	if serial % 4 == 2:
		return [[
			_create_enemy(tile, "bat", EnemyCatalog.ID_BAT),
		], [
			_create_enemy(tile, "grunt", EnemyCatalog.ID_GRUNT),
		]]
	if serial % 4 == 3:
		return [[
			_create_enemy(tile, "guard", EnemyCatalog.ID_GUARD),
		], [
			_create_enemy(tile, "grunt", EnemyCatalog.ID_GRUNT),
		]]
	return [[
		_create_enemy(tile, "grunt", EnemyCatalog.ID_GRUNT),
		_create_enemy(tile, "guard", EnemyCatalog.ID_GUARD),
	], [
		_create_enemy(tile, "bat", EnemyCatalog.ID_BAT),
	]]


func _elite_enemy_rows(tile: DungeonTile) -> Array:
	if run_state.stage_index >= 2:
		return [[
			_create_enemy(tile, "brute", EnemyCatalog.ID_BRUTE),
			_create_enemy(tile, "bat", EnemyCatalog.ID_BAT),
		], [
			_create_enemy(tile, "guard", EnemyCatalog.ID_GUARD),
		]]
	return [[
		_create_enemy(tile, "brute", EnemyCatalog.ID_BRUTE),
		_create_enemy(tile, "guard", EnemyCatalog.ID_GUARD),
	], [
		_create_enemy(tile, "grunt", EnemyCatalog.ID_GRUNT),
	]]


func _boss_enemy_rows(tile: DungeonTile) -> Array:
	if run_state.stage_index >= 2:
		return [[
			_create_enemy(tile, "guard_a", EnemyCatalog.ID_BOSS_GUARD),
			_create_enemy(tile, "guard_b", EnemyCatalog.ID_GUARD),
		], [
			_create_enemy(tile, "brute", EnemyCatalog.ID_BRUTE),
		], [
			_create_enemy(tile, "boss", EnemyCatalog.ID_STAGE_BOSS),
		]]
	return [[
		_create_enemy(tile, "guard_a", EnemyCatalog.ID_BOSS_GUARD),
		_create_enemy(tile, "guard_b", EnemyCatalog.ID_BOSS_GUARD),
	], [
		_create_enemy(tile, "boss", EnemyCatalog.ID_STAGE_BOSS),
	]]


func _create_enemy(tile: DungeonTile, suffix: String, catalog_id: String) -> CombatantState:
	return EnemyCatalog.create_enemy("%s_%s" % [tile.occupant_id, suffix], catalog_id)


func _encounter_serial(tile: DungeonTile) -> int:
	var parts := tile.occupant_id.split("_")
	if parts.is_empty():
		return 1
	var suffix := str(parts[parts.size() - 1])
	if suffix.is_valid_int():
		return int(suffix)
	return 1


func _create_combat_for_tile(tile: DungeonTile) -> CombatState:
	var player := CombatantState.new("hero", "英雄", run_state.max_health, 0, run_state.health)
	var combat := CombatState.new()
	var deck_cards := run_state.create_deck_cards()
	if deck_cards.is_empty():
		deck_cards = StarterCardCatalog.create_starter_deck()
	var defeated_count := 0
	if run_state.dungeon_map != null:
		defeated_count = run_state.dungeon_map.defeated_enemy_ids.size()
	combat.setup(
		player,
		deck_cards,
		create_enemy_rows_for_tile(tile),
		run_state.seed + run_state.stage_index + defeated_count,
		run_state.max_mana,
		5
	)
	return combat


func _active_enemy_display_name() -> String:
	if active_combat != null:
		var front_enemies := active_combat.front_row_enemies()
		if not front_enemies.is_empty():
			var front_enemy: CombatantState = front_enemies[0]
			return front_enemy.display_name
		var living := active_combat.living_enemies()
		if not living.is_empty():
			var enemy: CombatantState = living[0]
			return enemy.display_name
	if active_encounter_display_name != "":
		return active_encounter_display_name
	return "敌人"


func _encounter_display_name_for_tile(tile: DungeonTile) -> String:
	if tile.tile_type == DungeonTile.TileType.ELITE:
		return "精英"
	if tile.tile_type == DungeonTile.TileType.BOSS:
		return "首领"
	return "敌人"


func _xp_reward_for_active_encounter() -> int:
	if run_state.dungeon_map == null:
		return 0
	var tile: DungeonTile = run_state.dungeon_map.get_tile(active_encounter_position)
	if tile == null:
		return 0
	return xp_reward_for_tile_type(tile.tile_type)


func _clear_active_encounter() -> void:
	mode = MODE_EXPLORATION
	active_combat = null
	active_encounter_id = ""
	active_encounter_display_name = ""
	active_encounter_position = Vector2i.ZERO


func _clear_reward_state() -> void:
	pending_reward_level_events.clear()
	active_reward_level_event.clear()
	active_reward_source = ""
	active_reward_title = ""
	active_reward_pickup_id = ""
	pending_reward_choices.clear()


func _clear_run_end_state() -> void:
	active_run_end_reason = ""
	active_run_end_title = ""
	active_run_end_summary = ""


func _start_level_rewards(level_events: Array) -> void:
	pending_reward_level_events = level_events.duplicate(true)
	_start_next_queued_reward()


func _start_next_queued_reward() -> void:
	if pending_reward_level_events.is_empty():
		_clear_reward_state()
		mode = MODE_EXPLORATION
		return
	active_reward_level_event = pending_reward_level_events.pop_front()
	active_reward_source = REWARD_SOURCE_LEVEL_UP
	active_reward_title = "升级奖励：等级 %s" % int(active_reward_level_event.get("level", run_state.level))
	active_reward_pickup_id = ""
	pending_reward_choices = create_level_up_reward_choices(active_reward_level_event)
	mode = MODE_REWARD


func _start_treasure_reward(pickup_event: Dictionary) -> void:
	pending_reward_level_events.clear()
	active_reward_level_event.clear()
	active_reward_source = REWARD_SOURCE_TREASURE
	active_reward_title = "宝箱奖励"
	active_reward_pickup_id = str(pickup_event.get("occupant_id", ""))
	pending_reward_choices = create_level_up_reward_choices()
	mode = MODE_REWARD


func _apply_pickup_effect(event: Dictionary) -> void:
	var tile_type := int(event.get("tile_type", -1))
	event["pickup_type"] = _pickup_type_name(tile_type)
	if tile_type == DungeonTile.TileType.TREASURE:
		_start_treasure_reward(event)
		_add_reward_fields(event)
		return
	if tile_type == DungeonTile.TileType.HEALING:
		var recovered := run_state.heal(HEALING_PICKUP_AMOUNT)
		event["heal_amount"] = HEALING_PICKUP_AMOUNT
		event["health_recovered"] = recovered
		event["health"] = run_state.health
		event["max_health"] = run_state.max_health
		return
	if tile_type == DungeonTile.TileType.XP_GEM:
		var level_events := run_state.gain_xp(XP_GEM_REWARD)
		event["xp_gained"] = XP_GEM_REWARD
		event["level_events"] = level_events
		event["level"] = run_state.level
		event["xp"] = run_state.xp
		event["next_level_xp"] = run_state.next_level_xp
		if not level_events.is_empty():
			_start_level_rewards(level_events)
			_add_reward_fields(event)
		return


func _advance_stage_or_end_run(exit_event: Dictionary) -> Dictionary:
	var previous_stage_id := run_state.current_stage.id
	var previous_stage_name := run_state.current_stage.display_name
	if run_state.has_next_stage():
		var next_map := run_state.start_next_stage()
		_clear_active_encounter()
		_clear_reward_state()
		_clear_run_end_state()
		var result := exit_event.duplicate(true)
		result["type"] = EVENT_STAGE_ADVANCED
		result["reason"] = "stage_advanced"
		result["previous_stage_id"] = previous_stage_id
		result["previous_stage_display_name"] = previous_stage_name
		result["stage_index"] = run_state.stage_index
		result["stage_id"] = run_state.current_stage.id
		result["stage_display_name"] = run_state.current_stage.display_name
		result["position"] = next_map.player_position
		return result

	_start_run_victory()
	var final_result := exit_event.duplicate(true)
	final_result["type"] = EVENT_RUN_WON
	final_result["reason"] = "run_won"
	final_result["previous_stage_id"] = previous_stage_id
	final_result["previous_stage_display_name"] = previous_stage_name
	_add_run_end_fields(final_result)
	return final_result


func _start_run_defeat() -> void:
	var defeated_by := _active_enemy_display_name()
	var summary := "你被%s击倒。到达%s，等级 %s，牌组 %s 张。" % [
		defeated_by,
		run_state.current_stage.display_name,
		run_state.level,
		run_state.deck_card_ids.size(),
	]
	_start_run_end("defeat", "冒险结束", summary)


func _start_run_victory() -> void:
	var summary := "你突破了%s。等级 %s，经验 %s/%s，牌组 %s 张。" % [
		run_state.current_stage.display_name,
		run_state.level,
		run_state.xp,
		run_state.next_level_xp,
		run_state.deck_card_ids.size(),
	]
	_start_run_end("victory", "原型通关", summary)


func _start_run_end(reason: String, title: String, summary: String) -> void:
	active_run_end_reason = reason
	active_run_end_title = title
	active_run_end_summary = summary
	active_combat = null
	active_encounter_id = ""
	active_encounter_display_name = ""
	active_encounter_position = Vector2i.ZERO
	_clear_reward_state()
	mode = MODE_RUN_END


func _add_run_end_fields(event: Dictionary) -> void:
	event["run_end_reason"] = active_run_end_reason
	event["run_end_title"] = active_run_end_title
	event["run_end_summary"] = active_run_end_summary
	event["level"] = run_state.level
	event["health"] = run_state.health
	event["deck_size"] = run_state.deck_card_ids.size()


func _add_reward_fields(event: Dictionary) -> void:
	event["reward_source"] = active_reward_source
	event["reward_title"] = active_reward_title
	event["pickup_id"] = active_reward_pickup_id
	event["reward_choices"] = pending_reward_choices.duplicate(true)
	event["reward_pending_count"] = pending_reward_level_events.size()


func _pickup_type_name(tile_type: int) -> String:
	if tile_type == DungeonTile.TileType.TREASURE:
		return "treasure"
	if tile_type == DungeonTile.TileType.HEALING:
		return "healing"
	if tile_type == DungeonTile.TileType.XP_GEM:
		return "xp_gem"
	if tile_type == DungeonTile.TileType.FORGE:
		return "forge"
	if tile_type == DungeonTile.TileType.SHRINE:
		return "shrine"
	if tile_type == DungeonTile.TileType.HAZARD:
		return "hazard"
	return "pickup"


func _choice_is_pending(choice: Dictionary) -> bool:
	var card_id := str(choice.get("card_id", ""))
	for raw_pending_choice in pending_reward_choices:
		var pending_choice: Dictionary = raw_pending_choice
		if str(pending_choice.get("card_id", "")) == card_id:
			return true
	return false


func _add_play_result_fields(event: Dictionary, card: CardDefinition, play_result: CardPlayResult) -> void:
	event["play_result"] = play_result
	event["card_display_name"] = card.display_name if card != null else ""
	event["card_id"] = card.id if card != null else ""
	event["target_id"] = play_result.target_id
	event["target_ids"] = play_result.target_ids.duplicate()
	event["hit_events"] = play_result.hit_events.duplicate(true)
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
